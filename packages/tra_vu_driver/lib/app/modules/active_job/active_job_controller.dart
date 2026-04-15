import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tra_vu_core/models/job_status.dart';
import 'package:tra_vu_core/sockets/tracking_socket_service.dart';

import '../../services/driver_location_service.dart';
import '../../utils/currency_format.dart';

class ActiveJobController extends GetxController {
  final TrackingSocketService _socketService =
      Get.find<TrackingSocketService>();
  final DriverLocationService _locationService =
      Get.find<DriverLocationService>();

  final String jobId;
  final Map<String, dynamic> jobOffer;

  ActiveJobController({required this.jobId, required this.jobOffer});

  final Rx<JobStatus> status = JobStatus.accepted.obs;
  final Rx<LatLng> driverLocation = const LatLng(6.5244, 3.3792).obs;
  final Rx<LatLng> customerLocation = const LatLng(6.5400, 3.3900).obs;

  /// flutter_map controller — replaces GoogleMapController.
  final MapController mapController = MapController();
  Worker? _locationWorker;

  @override
  void onInit() {
    super.onInit();
    _socketService.subscribeToJob(jobId);
    _locationService.activeJobId.value = jobId;
    _locationService.setActiveTripTracking(true);
    _seedTripState();

    final currentLocation = _locationService.currentLocation.value;
    if (currentLocation != null) {
      driverLocation.value = currentLocation;
    }

    _locationWorker = ever<LatLng?>(_locationService.currentLocation, (
      location,
    ) {
      if (location == null) return;
      driverLocation.value = location;
      _animateCamera();
    });

    _socketService.listenToJobStatus((data) {
      final raw = data['status'] as String?;
      if (raw != null) {
        status.value = JobStatusExtension.fromString(raw);
        _setDestinationForStatus(status.value);
        if (status.value == JobStatus.completed) {
          Get.toNamed('/trip-summary', arguments: _summaryArgs());
        }
      }
    });
  }

  void advanceStatus() {
    final nextStatus = _nextMilestone(status.value);
    if (nextStatus == null) return;

    _socketService.emitStatusUpdate(jobId, nextStatus.name);
    status.value = nextStatus;
    _setDestinationForStatus(nextStatus);

    if (nextStatus == JobStatus.completed) {
      Get.toNamed('/trip-summary', arguments: _summaryArgs());
    }
  }

  String get sliderLabel {
    switch (status.value) {
      case JobStatus.accepted:
      case JobStatus.enroute:
        return 'Slide to Arrive';
      case JobStatus.arrived:
        return 'Slide to Start Trip';
      case JobStatus.in_progress:
        return 'Slide to Request Payment';
      case JobStatus.pending_payment:
        return 'Slide to Complete';
      default:
        return 'Trip Ended';
    }
  }

  String get customerName =>
      jobOffer['customerName']?.toString() ??
      jobOffer['customer']?['firstName']?.toString() ??
      'Customer';

  String get customerPhone => jobOffer['customerPhone']?.toString() ?? '';

  String get customerInitial {
    final trimmed = customerName.trim();
    if (trimmed.isEmpty) return 'C';
    return trimmed[0].toUpperCase();
  }

  String get pickupAddress =>
      jobOffer['pickupAddress']?.toString() ??
      jobOffer['pickupLocation']?['address']?.toString() ??
      'Pickup pending';

  String get dropoffAddress =>
      jobOffer['dropoffAddress']?.toString() ??
      jobOffer['dropoffLocation']?['address']?.toString() ??
      'Dropoff pending';

  String get earningsLabel {
    final currency =
        jobOffer['currency']?.toString() ??
        jobOffer['driver']?['currency']?.toString();
    final raw =
        jobOffer['estimatedEarnings'] ??
        jobOffer['estimatedPrice'] ??
        jobOffer['finalPrice'];
    return formatCurrencyAmount(
      parseCurrencyAmount(raw),
      currencyCode: currency,
    );
  }

  String get destinationTitle {
    switch (status.value) {
      case JobStatus.accepted:
      case JobStatus.enroute:
      case JobStatus.arrived:
        return 'Pickup';
      case JobStatus.in_progress:
      case JobStatus.completed:
        return 'Dropoff';
      default:
        return 'Destination';
    }
  }

  JobStatus? _nextMilestone(JobStatus current) {
    switch (current) {
      case JobStatus.accepted:
        return JobStatus.enroute;
      case JobStatus.enroute:
        return JobStatus.arrived;
      case JobStatus.arrived:
        return JobStatus.in_progress;
      case JobStatus.in_progress:
        return JobStatus.pending_payment;
      case JobStatus.pending_payment:
        return JobStatus.completed;
      default:
        return null;
    }
  }

  void _seedTripState() {
    final currentStatus = jobOffer['status']?.toString();
    if (currentStatus != null) {
      status.value = JobStatusExtension.fromString(currentStatus);
    }
    _setDestinationForStatus(status.value);
  }

  void _setDestinationForStatus(JobStatus nextStatus) {
    final pickup = _parseLatLng(jobOffer['pickupLocation']);
    final dropoff = _parseLatLng(jobOffer['dropoffLocation']);

    if (nextStatus == JobStatus.in_progress ||
        nextStatus == JobStatus.pending_payment ||
        nextStatus == JobStatus.completed) {
      customerLocation.value = dropoff ?? pickup ?? customerLocation.value;
      return;
    }

    customerLocation.value = pickup ?? dropoff ?? customerLocation.value;
  }

  LatLng? _parseLatLng(dynamic rawLocation) {
    if (rawLocation is! Map) return null;
    final lat = rawLocation['lat'];
    final lng = rawLocation['lng'];
    if (lat is! num || lng is! num) return null;
    return LatLng(lat.toDouble(), lng.toDouble());
  }

  Map<String, dynamic> _summaryArgs() {
    return {
      'jobId': jobId,
      'earnings':
          jobOffer['estimatedEarnings'] ?? jobOffer['estimatedPrice'] ?? '0.00',
      'currency': jobOffer['currency'],
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'customerName': customerName,
    };
  }

  void _animateCamera() {
    final dLat = driverLocation.value.latitude;
    final dLng = driverLocation.value.longitude;
    final cLat = customerLocation.value.latitude;
    final cLng = customerLocation.value.longitude;

    // Centre the map on the midpoint of driver ↔ customer
    final midLat = (dLat + cLat) / 2;
    final midLng = (dLng + cLng) / 2;
    mapController.move(LatLng(midLat, midLng), 14.0);
  }

  @override
  void onClose() {
    _locationWorker?.dispose();
    _locationService.setActiveTripTracking(false);
    _locationService.activeJobId.value = null;
    super.onClose();
  }
}
