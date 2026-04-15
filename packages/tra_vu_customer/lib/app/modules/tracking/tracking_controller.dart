import 'dart:async';

import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tra_vu_core/api/customer_api.dart';
import 'package:tra_vu_core/models/models.dart';
import 'package:tra_vu_core/sockets/tracking_socket_service.dart';

class TrackingController extends GetxController {
  final TrackingSocketService _socketService =
      Get.find<TrackingSocketService>();
  final CustomerApi _customerApi = Get.find<CustomerApi>();

  final String activeJobId;
  final Rxn<JobModel> currentJob = Rxn<JobModel>();
  final Rx<JobStatus> currentStatus = JobStatus.created.obs;
  final Rx<LatLng> driverLocation = const LatLng(37.7749, -122.4194).obs;
  final RxBool isLoading = true.obs;
  Timer? _jobRefreshTimer;

  TrackingController(this.activeJobId);

  @override
  void onInit() {
    super.onInit();

    final routeArguments = Get.arguments;
    if (routeArguments is Map<String, dynamic>) {
      final job = JobModel.fromMap(routeArguments);
      currentJob.value = job;
      currentStatus.value = job.status;
      driverLocation.value = LatLng(
        job.pickupLocation.lat,
        job.pickupLocation.lng,
      );
      isLoading.value = false;
    }

    _loadJob();

    // Wire up listeners immediately
    _socketService.subscribeToJob(activeJobId);
    _startJobRefreshPolling();

    _socketService.listenToJobStatus((data) {
      final rawStatus = data['status'];
      if (rawStatus != null) {
        currentStatus.value = JobStatusExtension.fromString(rawStatus);
        final job = currentJob.value;
        if (job != null) {
          currentJob.value = job.copyWith(status: currentStatus.value);
        }
      }

      _refreshJobSilently();
    });

    _socketService.listenToDriverLocation((data) {
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        driverLocation.value = LatLng(lat, lng);
      }
    });
  }

  Future<void> _loadJob() async {
    try {
      final job = await _customerApi.getJob(activeJobId);
      currentJob.value = job;
      currentStatus.value = job.status;
      if (job.driver == null) {
        driverLocation.value = LatLng(
          job.pickupLocation.lat,
          job.pickupLocation.lng,
        );
      }
    } catch (_) {
      // Keep any optimistic route argument data if the fetch fails.
    } finally {
      isLoading.value = false;
    }
  }

  void _startJobRefreshPolling() {
    _jobRefreshTimer?.cancel();
    _jobRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_shouldContinuePolling) {
        _refreshJobSilently();
      }
    });
  }

  bool get _shouldContinuePolling {
    final status = currentStatus.value;
    return status == JobStatus.created ||
        status == JobStatus.matched ||
        status == JobStatus.accepted;
  }

  Future<void> _refreshJobSilently() async {
    try {
      final job = await _customerApi.getJob(activeJobId);
      currentJob.value = job;
      currentStatus.value = job.status;

      if (job.driver == null) {
        driverLocation.value = LatLng(
          job.pickupLocation.lat,
          job.pickupLocation.lng,
        );
      }
    } catch (_) {
      // Ignore background refresh failures and keep the latest known state.
    }
  }

  @override
  void onClose() {
    _jobRefreshTimer?.cancel();
    // _socketService.unsubscribeFromJob(activeJobId);
    super.onClose();
  }
}
