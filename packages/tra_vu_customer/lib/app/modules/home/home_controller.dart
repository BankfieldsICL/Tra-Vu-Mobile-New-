import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tra_vu_core/tra_vu_core.dart';
import 'package:tra_vu_customer/app/services/location_service.dart';

enum ServiceType { rideHailing, carpooling, packageDelivery }

class HomeController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final CustomerApi _customerApi = Get.find<CustomerApi>();
  final AuthService _authService = Get.find<AuthService>();
  final OsmLocationService _locationService = Get.find<OsmLocationService>();

  final Rxn<LocationModel> pickupLocation = Rxn<LocationModel>();
  final Rxn<LocationModel> destinationLocation = Rxn<LocationModel>();

  final Rx<ServiceType> activeService = ServiceType.rideHailing.obs;
  final RxList<String> availableVehicles = <String>[].obs;
  final Rxn<UserModel> profile = Rxn<UserModel>();
  final RxList<TripMemberModel> myActiveTrips = <TripMemberModel>[].obs;
  final RxList<TripModel> availableTrips = <TripModel>[].obs;
  final RxBool isLoadingTrips = false.obs;
  final RxnString loadError = RxnString();

  // Wallet Balance State
  final RxDouble walletBalance = 0.0.obs;
  final RxString walletCurrency = 'NGN'.obs;
  final RxBool isBalanceVisible = true.obs;

  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxList<JobModel> recentJobs = <JobModel>[].obs;
  final Rxn<PricingRuleModel> activePricingRule = Rxn<PricingRuleModel>();
  final Rx<LatLng> mapCenter = const LatLng(6.5244, 3.3792).obs; // Default to Lagos city center
  final MapController mapController = MapController();

  @override
  void onInit() {
    super.onInit();
    refreshMapAssets(activeService.value);
    refreshHomeData();
    // Pre-fetch trips so the carpool panel is ready immediately
    fetchAvailableTrips();
    // Re-fetch trips whenever the destination changes
    ever(destinationLocation, (_) => fetchAvailableTrips());
  }

  void switchService(ServiceType type) {
    if (activeService.value == type) return;
    activeService.value = type;
    refreshMapAssets(type);
    if (type == ServiceType.carpooling) {
      fetchAvailableTrips();
    }
  }

  Future<void> refreshHomeData({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
    }
    isRefreshing.value = true;
    loadError.value = null;

    try {
      await Future.wait([
        _loadProfile(),
        _loadJobs(),
        _loadPricingRule(),
        _loadCurrentLocation(),
        _loadWalletBalance(),
        fetchMyTrips(),
      ]);
    } catch (error) {
      loadError.value = _readableErrorMessage(
        error,
        fallback: 'We could not refresh your customer dashboard right now.',
      );
    } finally {
      isRefreshing.value = false;
      isLoading.value = false;
    }
  }

  void refreshMapAssets(ServiceType type) {
    availableVehicles.clear();
    if (type == ServiceType.packageDelivery) {
      availableVehicles.addAll(['Motorcycle', 'Van', 'Truck']);
    } else if (type == ServiceType.rideHailing) {
      availableVehicles.addAll(['Economy', 'Premium', 'XL']);
    } else if (type == ServiceType.carpooling) {
      availableVehicles.addAll(['Scheduled Trip 1', 'Scheduled Trip 2']);
    }
  }

  String get displayName {
    final user = profile.value;
    if (user == null) {
      return 'Customer';
    }

    final fullName = '${user.firstName} ${user.lastName}'.trim();
    debugPrint('Computed displayName: $fullName');
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return user.email ?? user.phoneNumber ?? 'Customer';
  }

  String get contactLabel {
    return profile.value?.email ??
        profile.value?.phoneNumber ??
        _authService.currentAuthEmail ??
        _authService.currentAuthPhone ??
        'Signed in';
  }

  Future<void> _loadProfile() async {
    profile.value = await _customerApi.getProfile();
  }

  Future<void> _loadJobs() async {
    final response = await _apiClient.dio.get(ApiEndpoints.jobs);
    final payload = _unwrapCollection(response.data);
    recentJobs.assignAll(
      payload
          .whereType<Map>()
          .map((entry) => JobModel.fromMap(Map<String, dynamic>.from(entry)))
          .toList(),
    );
  }

  Future<void> _loadPricingRule() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.pricingRules,
        queryParameters: const {'currency': 'NGN'},
      );
      final payload = _unwrapObject(response.data);
      if (payload != null) {
        activePricingRule.value = PricingRuleModel.fromMap(payload);
      }
    } catch (_) {
      activePricingRule.value = null;
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      mapCenter.value = LatLng(position.latitude, position.longitude);

      // Update Pickup Location Address initially
      final place = await _locationService.reverseGeocode(
          position.latitude, position.longitude);
      if (place != null) {
        pickupLocation.value = OsmLocationService.placeToLocationModel(place);
      }
    } catch (_) {
      // Keep the default city center if location is unavailable.
    }
  }

  List<dynamic> _unwrapCollection(dynamic rawData) {
    if (rawData is List) {
      return rawData;
    }

    if (rawData is Map<String, dynamic>) {
      final data = rawData['data'];
      if (data is List) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        final collection = data['items'] ?? data['jobs'] ?? data['results'];
        if (collection is List) {
          return collection;
        }
      }
    }

    return const [];
  }

  Future<void> fetchMyTrips() async {
    try {
      final memberships = await _customerApi.getMyTripMemberships();
      debugPrint('Fetched ${memberships.first.toMap()} of ${memberships.length} trip memberships');
      myActiveTrips.assignAll(memberships.where((m) => 
        m.status == TripMemberStatus.approved || 
        m.status == TripMemberStatus.pending
      ));
    } catch (e) {
      debugPrint('Error fetching my trips: $e');
    }
  }

  Future<void> updatePickupFromMap(LatLng position) async {
    mapCenter.value = position;
    final place = await _locationService.reverseGeocode(
        position.latitude, position.longitude);
    if (place != null) {
      pickupLocation.value = OsmLocationService.placeToLocationModel(place);
    }
  }

  /// Called when the user selects a [Place] from the search overlay.
  /// With Nominatim the full coordinates are already in the [Place] object,
  /// so no secondary "get details" call is needed.
  void selectPlace(Place place, {required bool isDestination}) {
    final loc = OsmLocationService.placeToLocationModel(place);
    if (isDestination) {
      destinationLocation.value = loc;
    } else {
      pickupLocation.value = loc;
      mapCenter.value = LatLng(loc.lat, loc.lng);
    }
  }

  Future<void> fetchAvailableTrips() async {
    isLoadingTrips.value = true;
    try {
      final pickup = pickupLocation.value;
      final dropoff = destinationLocation.value;

      final trips = await _customerApi.searchTrips(
        pickupLat: pickup?.lat,
        pickupLng: pickup?.lng,
        dropoffLat: dropoff?.lat,
        dropoffLng: dropoff?.lng,
      );
      availableTrips.assignAll(trips);
    } catch (e) {
      debugPrint('Error fetching trips: $e');
    } finally {
      isLoadingTrips.value = false;
    }
  }

  Future<void> joinTrip(TripModel trip) async {
    try {
      await _customerApi.requestToJoinTrip(trip.id, 1);
      Get.snackbar(
        'Request Sent',
        'Your request to join specified trip has been sent to the driver.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      fetchAvailableTrips(); // Refresh to show pending status if applicable
    } catch (e) {
      Get.snackbar(
        'Request Failed',
        'We could not send your join request. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Map<String, dynamic>? _unwrapObject(dynamic rawData) {
    if (rawData is Map<String, dynamic>) {
      final data = rawData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }

      return rawData;
    }

    return null;
  }

  Future<void> _loadWalletBalance() async {
    try {
      final userId = _authService.currentUserId.value;
      if (userId == null) return;

      final response = await _apiClient.dio.get(
        ApiEndpoints.paymentBalance(userId),
        queryParameters: const {'currency': 'NGN'},
      );

      final payload = _unwrapObject(response.data);
      if (payload != null) {
        final amountMinor = payload['availableBalance'] ??
            payload['balance'] ??
            payload['amount'] ??
            0;
        walletBalance.value = (amountMinor as num).toDouble() / 100;
        walletCurrency.value =
            (payload['currency']?.toString() ?? 'NGN').toUpperCase();
      }
    } catch (_) {
      // Fail silently for balance in home view
    }
  }

  String _readableErrorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }

      final dioMessage = error.message?.trim();
      if (dioMessage != null && dioMessage.isNotEmpty) {
        return dioMessage;
      }
    }

    return fallback;
  }
}
