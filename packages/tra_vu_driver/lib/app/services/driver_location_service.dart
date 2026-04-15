import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tra_vu_core/config/api_config.dart';
import 'package:tra_vu_core/services/auth_service.dart';
import 'package:tra_vu_core/sockets/tracking_socket_service.dart';

class DriverLocationService extends GetxService {
  final TrackingSocketService _socketService =
      Get.find<TrackingSocketService>();
  final AuthService _authService = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : Get.put(AuthService());

  final Rxn<LatLng> currentLocation = Rxn<LatLng>();
  final RxnString activeJobId = RxnString();
  
  /// Callback triggered when location services are disabled or permissions lost while tracking.
  void Function()? onLocationServiceLost;

  StreamSubscription<Position>? _positionSubscription;
  bool _onlineTrackingEnabled = false;
  bool _activeTripTrackingEnabled = false;

  Future<bool> setOnlineTracking(bool enabled) async {
    _onlineTrackingEnabled = enabled;
    return _syncTrackingState();
  }

  Future<bool> setActiveTripTracking(bool enabled) async {
    _activeTripTrackingEnabled = enabled;
    return _syncTrackingState();
  }

  Future<bool> _syncTrackingState() async {
    final shouldTrack = _onlineTrackingEnabled || _activeTripTrackingEnabled;
    final bgService = FlutterBackgroundService();

    if (!shouldTrack) {
      debugPrint('Main Isolate: Invoking stopTracking');
      bgService.invoke('stopTracking');
      await _stopTracking();
      return true;
    }

    if (_positionSubscription != null) {
      return true;
    }

    final hasPermission = await _ensureLocationAccess();
    if (!hasPermission) {
      _onlineTrackingEnabled = false;
      _activeTripTrackingEnabled = false;
      return false;
    }

    bool isRunning = await bgService.isRunning();

    if (!isRunning) {
      await bgService.startService();
      await Future.delayed(const Duration(seconds: 1)); // allow bootstrap
      bgService.invoke('setAsForeground');
    }

    // Start background tracking isolate as well
    debugPrint('Main Isolate: Invoking startTracking (token present: ${_authService.currentUserToken.value != null} ${ApiConfig.baseSocketUrl})');
    bgService.invoke('startTracking', {
      'token': _authService.currentUserToken.value,
      'baseUrl': ApiConfig.baseSocketUrl, // Matching AuthService
      'jobId': activeJobId.value,
    });

    await _pushCurrentLocation();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            _handlePosition(position);
          },
          onError: (error) {
            debugPrint('DriverLocationService: Position stream error: $error');
            if (error is LocationServiceDisabledException) {
              onLocationServiceLost?.call();
            }
          },
        );

    return true;
  }

  Future<bool> _ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _pushCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    _handlePosition(position);
  }

  void _handlePosition(Position position) {
    final latLng = LatLng(position.latitude, position.longitude);
    currentLocation.value = latLng;

    if (_socketService.isConnected.value) {
      _socketService.updateLocation(
        latLng.latitude,
        latLng.longitude,
        jobId: activeJobId.value,
      );
    }
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    super.onClose();
  }
}
