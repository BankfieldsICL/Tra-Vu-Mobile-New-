import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/tra_vu_core.dart';

import 'home_controller.dart';

class RideBookingController extends GetxController {
  final CustomerApi _customerApi = Get.find<CustomerApi>();

  final Rx<MatchingMode> matchingMode = MatchingMode.instant.obs;
  final Rx<PaymentMode> paymentMode = PaymentMode.wallet.obs;
  final RxString selectedVehicle = 'Economy'.obs;
  final RxBool isSubmitting = false.obs;
  final Rxn<JobModel> latestJob = Rxn<JobModel>();

  void setMatchingMode(MatchingMode? value) {
    if (value == null) return;
    matchingMode.value = value;
  }

  void setPaymentMode(PaymentMode? value) {
    if (value == null) return;
    paymentMode.value = value;
  }

  void setVehicle(String value) {
    selectedVehicle.value = value;
  }

  Future<void> createRideJob() async {
    final homeController = Get.find<HomeController>();
    final pickup = homeController.pickupLocation.value;
    final dropoff = homeController.destinationLocation.value;

    if (pickup == null) {
      Get.snackbar('Missing Pickup', 'Choose a pickup location first.');
      return;
    }

    if (dropoff == null) {
      Get.snackbar('Missing Destination', 'Choose a destination before requesting a ride.');
      return;
    }

    isSubmitting.value = true;

    try {
      final job = await _customerApi.createJob(
        type: JobType.ride,
        pickupLat: pickup.lat,
        pickupLng: pickup.lng,
        pickupAddress: pickup.address,
        dropoffLat: dropoff.lat,
        dropoffLng: dropoff.lng,
        dropoffAddress: dropoff.address,
        matchingMode: matchingMode.value,
        paymentMode: paymentMode.value,
        currency: 'NGN',
      );

      latestJob.value = job;
      await homeController.refreshHomeData(silent: true);

      final summary = job.estimatedPrice != null
          ? 'Estimated fare: ${formatMajorAmount(job.estimatedPrice!, job.currency)}'
          : 'Ride request submitted successfully.';
      Get.snackbar('Ride Requested', summary);
      Get.toNamed('/tracking?jobId=${job.id}', arguments: job.toJson());
    } catch (error) {
      Get.snackbar(
        'Unable to Request Ride',
        _readableErrorMessage(
          error,
          fallback: 'Please review the ride details and try again.',
        ),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  String formatMinorAmount(int amount, String currency) {
    final major = (amount / 100).toStringAsFixed(2);
    return '${currency.toUpperCase()} $major';
  }

  String formatMajorAmount(int amount, String currency) {
    final major = (amount).toStringAsFixed(2);
    return '${currency.toUpperCase()} $major';
  }

  String _readableErrorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'];
        final message = payload is Map<String, dynamic>
            ? payload['message'] ?? data['message']
            : data['message'];

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
