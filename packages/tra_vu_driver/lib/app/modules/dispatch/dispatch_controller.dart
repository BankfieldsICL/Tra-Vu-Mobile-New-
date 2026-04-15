import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/api/driver_api.dart';
import 'package:tra_vu_core/models/models.dart';
import 'package:tra_vu_core/services/auth_service.dart';
import 'package:tra_vu_core/sockets/tracking_socket_service.dart';

import '../../services/driver_location_service.dart';
import '../../utils/currency_format.dart';
import 'widgets/job_offer_sheet.dart';

class DispatchController extends GetxController with WidgetsBindingObserver {
  final TrackingSocketService _socketService =
      Get.find<TrackingSocketService>();
  final DriverLocationService _locationService =
      Get.find<DriverLocationService>();
  final DriverApi _driverApi = Get.find<DriverApi>();
  final AuthService _authService = Get.find<AuthService>();

  final Rxn<JobModel> activeJobOffer = Rxn<JobModel>();
  final Rxn<DriverModel> currentDriver = Rxn<DriverModel>();
  final RxList<JobModel> recentJobs = <JobModel>[].obs;
  final RxBool isOnline = false.obs;
  final RxBool isLoadingOverview = true.obs;
  final RxBool isAcceptingOffer = false.obs;
  final RxList<TripModel> myActiveTrips = <TripModel>[].obs;
  final RxMap<String, List<TripMemberModel>> tripMembers = <String, List<TripMemberModel>>{}.obs;
  final RxString socketStatus = 'Disconnected'.obs;

  final RxString statusMessage = 'Loading driver workspace...'.obs;
  final RxMap<String, double> todayEarningsByCurrency = <String, double>{}.obs;
  final RxInt completedTripsToday = 0.obs;
  bool _isWaitingForLocation = false;
  StreamSubscription<ServiceStatus>? _locationStatusSubscription;

  String get socketId => _socketService.socketId.value;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _registerSocketListeners();
    _setupTokenSync();
    _setupLocationStatusListener();
    _locationService.onLocationServiceLost = _forceOfflineDueToLocation;
    refreshOverview();
  }

  void _setupLocationStatusListener() {
    _locationStatusSubscription = Geolocator.getServiceStatusStream().listen((status) {
      if (status == ServiceStatus.disabled && isOnline.value) {
        _forceOfflineDueToLocation();
      }
    });
  }

  void _setupTokenSync() {
    ever(_authService.currentUserToken, (token) {
      if (token != null && token.isNotEmpty) {
        _socketService.pushNewToken(token);
      }
    });
  }

  Future<void> refreshOverview() async {
    isLoadingOverview.value = true;

    final userId = _authService.currentUserId.value;
    if (userId == null || userId.isEmpty) {
      statusMessage.value = 'Sign in to start receiving dispatch updates.';
      isLoadingOverview.value = false;
      return;
    }

    try {
      final driver = await _driverApi.getMyDriverProfile();

      currentDriver.value = driver;
      if (driver == null) {
        statusMessage.value =
            'Finish your driver setup to go online and receive job offers.';
        isOnline.value = false;
        recentJobs.clear();
        todayEarningsByCurrency.clear();
        completedTripsToday.value = 0;
        return;
      }

      isOnline.value =
          driver.status == DriverStatus.online ||
          driver.status == DriverStatus.on_trip;

      final jobs = await _driverApi.getJobs();
      final driverJobs = jobs.where((job) => job.driverId == driver.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      recentJobs.assignAll(driverJobs.take(5).toList());
      _calculateTodayStats(driverJobs);

      statusMessage.value = isOnline.value
          ? 'You are live and ready for your next request.'
          : 'Go online to start receiving jobs nearby.';
    } catch (_) {
      statusMessage.value =
          'We could not refresh dispatch data right now. Pull to retry.';
    } finally {
      fetchMyTrips();
      isLoadingOverview.value = false;
    }
  }

  Future<bool> createTrip({
    required int totalSeats,
    required DateTime departureTime,
    required LocationModel start,
    required LocationModel end,
    List<LocationModel> waypoints = const [],
  }) async {
    try {
      final route = RouteModel(
        start: start,
        end: end,
        waypoints: waypoints,
      );

      await _driverApi.createTrip(
        totalSeats: totalSeats,
        departureTime: departureTime,
        route: route,
      );

      await fetchMyTrips();
      return true;
    } catch (e) {
      debugPrint('Error creating trip: $e');
      Get.snackbar(
        'Error',
        'Could not create trip. Please check your connection and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> fetchMyTrips() async {
    try {
      final trips = await _driverApi.getMyTrips();
      myActiveTrips.assignAll(trips.where((trip) => 
        trip.status == TripStatus.planned || 
        trip.status == TripStatus.active
      ).toList());
      
      for (final trip in myActiveTrips) {
        final members = await _driverApi.getTripMembers(trip.id);
        tripMembers[trip.id] = members;
      }
    } catch (e) {
      debugPrint('Error fetching my trips: $e');
    }
  }

  Future<void> approveMember(String memberId) async {
    try {
      await _driverApi.approveTripMember(memberId);
      Get.snackbar('Success', 'Member approved');
      fetchMyTrips();
    } catch (e) {
      Get.snackbar('Error', 'Failed to approve member');
    }
  }

  Future<void> rejectMember(String memberId) async {
    try {
      await _driverApi.rejectTripMember(memberId);
      Get.snackbar('Success', 'Member rejected');
      fetchMyTrips();
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject member');
    }
  }

  Future<void> boardMember(String memberId, String otp) async {
    try {
      await _driverApi.boardTripMember(memberId, otp);
      Get.snackbar('Success', 'Member boarded');
      fetchMyTrips();
    } catch (e) {
      Get.snackbar('Error', 'Invalid OTP or boarding failed');
    }
  }

  Future<void> markNoShow(String memberId) async {
    try {
      await _driverApi.markTripMemberNoShow(memberId);
      Get.snackbar('Success', 'Member marked as no-show');
      fetchMyTrips();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update member status');
    }
  }

  Future<void> toggleOnlineStatus() async {
    final driver = currentDriver.value;
    if (driver == null) {
      Get.snackbar('Setup needed', 'Complete onboarding before you go online.');
      Get.toNamed('/auth/documents');
      return;
    }

    final shouldGoOnline = !isOnline.value;
    final success = await _locationService.setOnlineTracking(shouldGoOnline);

    if (!success) {
      _showLocationRequiredDialog();
      return;
    }

    try {
      final updatedDriver = await _driverApi.updateDriverStatus(
        driver.id,
        shouldGoOnline ? DriverStatus.online : DriverStatus.offline,
      );

      currentDriver.value = updatedDriver;
      isOnline.value = shouldGoOnline;
      statusMessage.value = shouldGoOnline
          ? 'You are live and waiting for nearby requests.'
          : 'You are offline. Go online when you are ready again.';

      if (shouldGoOnline) {
        _pushImmediateLocation();
      }
    } catch (_) {
      await _locationService.setOnlineTracking(false);
      Get.snackbar(
        'Status update failed',
        'We could not update your online status. Please try again.',
      );
    }
  }

  Future<void> acceptOffer() async {
    final offer = activeJobOffer.value;
    final jobId = offer?.id;
    if (jobId == null || jobId.isEmpty) {
      Get.snackbar('Offer unavailable', 'This offer is missing a job id.');
      return;
    }

    debugPrint('[DispatchController] Attempting to accept offer: $jobId');

    isAcceptingOffer.value = true;
    _socketService.acceptJob(jobId);

    try {
      final driver = currentDriver.value;
      if (driver != null) {
        currentDriver.value = await _driverApi.updateDriverStatus(
          driver.id,
          DriverStatus.on_trip,
        );
      }
    } catch (_) {}

    isAcceptingOffer.value = false;
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }

    if (offer != null) {
      Get.toNamed('/active-trip', arguments: offer.toMap());
    }
    activeJobOffer.value = null;
  }

  void declineOffer() {
    activeJobOffer.value = null;
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
  }

  void simulateIncomingOffer() {
    debugPrint(
      '[DispatchController] SIMULATING incoming offer for debugging...',
    );
    final fullJob = JobModel(
      id: 'debug-job-123',
      tenantId: 'debug-tenant',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      type: JobType.delivery,
      status: JobStatus.created,
      pickupLocation: const LocationModel(
        lat: 6.4637259,
        lng: 3.6661731,
        address: '123 Test Lane, Lagos',
      ),
      dropoffLocation: const LocationModel(
        lat: 6.4637259,
        lng: 3.6661731,
        address: '456 Debug Blvd, Victoria Island',
      ),
      estimatedPrice: 4500,
      currency: 'NGN',
    );
    activeJobOffer.value = fullJob;
    _showJobOfferBottomSheet(fullJob);
  }

  String get formattedTodayEarnings => todayEarningsByCurrency.isEmpty
      ? '--'
      : (todayEarningsByCurrency.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)))
            .map(
              (entry) =>
                  formatCurrencyAmount(entry.value, currencyCode: entry.key),
            )
            .join('\n');

  String get driverName {
    final user = currentDriver.value?.user;
    final fullName = [
      user?.firstName,
      user?.lastName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    return fullName.isEmpty ? 'Driver' : fullName;
  }

  Future<void> _pushImmediateLocation() async {
    final location = _locationService.currentLocation.value;
    if (location != null && isOnline.value) {
      debugPrint(
        '[DispatchController] Pushing immediate location update to ensure indexing',
      );
      _socketService.updateLocation(location.latitude, location.longitude);
    }
  }

  void _registerSocketListeners() {
    debugPrint(
      '[DispatchController] Registering real-time job offer listener...',
    );

    // Sync socket connection status for the UI
    ever(_socketService.isConnected, (connected) {
      socketStatus.value = connected ? 'Connected' : 'Disconnected';
      if (connected && isOnline.value) {
        _pushImmediateLocation(); // Re-index in Redis on reconnect
      }
    });
    socketStatus.value = _socketService.isConnected.value
        ? 'Connected'
        : 'Disconnected';

    _socketService.listenForJobOffers((offerData) async {
      debugPrint(
        '[DispatchController] Incoming real-time job offer: $offerData',
      );
      final jobId = offerData['jobId']?.toString();
      if (jobId == null) {
        debugPrint(
          '[DispatchController] Error: Received job offer without jobId',
        );
        return;
      }

      try {
        // Fetch full job details including type, price, addresses
        final fullJob = await _driverApi.getJob(jobId);
        debugPrint(
          '[DispatchController] Fetched full job details for offer: $fullJob',
        );
        activeJobOffer.value = fullJob;
        _showJobOfferBottomSheet(fullJob);
      } catch (e) {
        debugPrint(
          '[DispatchController] Error fetching offer details for $jobId: $e',
        );
      }
    });

    _socketService.listenForJobAcceptedSuccess((_) {
      Get.snackbar(
        'Offer accepted',
        'Head to pickup and keep the rider updated.',
      );
    });

    _socketService.listenForJobAcceptedError((data) {
      final message =
          data['message']?.toString() ?? 'This job is no longer available.';
      Get.snackbar('Offer unavailable', message);
      activeJobOffer.value = null;
    });
    debugPrint('[DispatchController] Listener registered successfully.');
  }

  void _showJobOfferBottomSheet(JobModel offer) {
    if (Get.isBottomSheetOpen ?? false) {
      return;
    }

    Get.bottomSheet(
      JobOfferBottomSheet(offer: offer, controller: this),
      isDismissible: false,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _calculateTodayStats(List<JobModel> driverJobs) {
    final now = DateTime.now();
    final todaysJobs = driverJobs.where(
      (job) =>
          job.createdAt.year == now.year &&
          job.createdAt.month == now.month &&
          job.createdAt.day == now.day,
    );

    final completedJobs = todaysJobs
        .where((job) => job.status == JobStatus.completed)
        .toList();

    completedTripsToday.value = completedJobs.length;
    final totalsByCurrency = <String, double>{};

    for (final job in completedJobs) {
      final currency = job.currency.trim().isEmpty ? 'USD' : job.currency;
      final amount = amountFromMinorUnits(job.finalPrice ?? job.estimatedPrice);
      totalsByCurrency.update(
        currency,
        (sum) => sum + amount,
        ifAbsent: () => amount,
      );
    }

    todayEarningsByCurrency.assignAll(totalsByCurrency);
  }

  void _getAccountBalance() async {
    try {
      final userId = _authService.currentUserId.value;
      if (userId == null) {
        debugPrint('Cannot fetch balance: No authenticated user.');
        throw StateError('Cannot fetch balance: No authenticated user');
        // return;
      }
      final balance = await _driverApi.getBalance(userId, currency: 'NGN');
      debugPrint('Current account balance: $balance');
    } catch (e) {
      debugPrint('Error fetching account balance: $e');
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationStatusSubscription?.cancel();
    _locationService.setOnlineTracking(false);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForLocation) {
      _isWaitingForLocation = false;
      // Close any open dialogs if we are auto-resuming
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      toggleOnlineStatus();
    }
  }

  void _showLocationRequiredDialog() {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF1D4ED8),
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Location Access',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'To go online and start receiving job offers, we need to track your location. Please enable location services in your system settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  _isWaitingForLocation = true;
                  Get.back();
                  _locationService.openLocationSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ENABLE IN SETTINGS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text(
                  'NOT NOW',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _forceOfflineDueToLocation() async {
    debugPrint('[DispatchController] Forcing offline: Location services disabled while online.');
    
    // 1. Update UI state immediately
    isOnline.value = false;
    statusMessage.value = 'Offline: Location services required.';
    
    // 2. Stop tracking
    await _locationService.setOnlineTracking(false);
    
    // 3. Update backend status if we have a driver profile
    final driver = currentDriver.value;
    if (driver != null) {
      try {
        currentDriver.value = await _driverApi.updateDriverStatus(
          driver.id,
          DriverStatus.offline,
        );
      } catch (e) {
        debugPrint('[DispatchController] Error updating status during force-offline: $e');
      }
    }

    // 4. Show the dialog to the user
    _showLocationRequiredDialog();
  }
}
