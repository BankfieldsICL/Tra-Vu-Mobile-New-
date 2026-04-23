import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/tra_vu_core.dart';
import 'home_controller.dart';

class DeliveryBookingController extends GetxController {
  final CustomerApi _customerApi = Get.find<CustomerApi>();

  final pickupAddressController = TextEditingController();
  final dropoffAddressController = TextEditingController();
  final senderNameController = TextEditingController();
  final senderPhoneController = TextEditingController();
  final receiverNameController = TextEditingController();
  final receiverPhoneController = TextEditingController();
  final packageTypeController = TextEditingController();
  final weightController = TextEditingController();
  final dimensionsController = TextEditingController();
  final notesController = TextEditingController();

  final Rx<MatchingMode> matchingMode = MatchingMode.instant.obs;
  final Rx<PaymentMode> paymentMode = PaymentMode.wallet.obs;
  final RxBool isSubmitting = false.obs;
  final Rxn<JobModel> latestJob = Rxn<JobModel>();

  @override
  void onInit() {
    super.onInit();
    final homeController = Get.find<HomeController>();
    
    // Sync Pickup Address
    ever(homeController.pickupLocation, (loc) {
      if (loc != null) pickupAddressController.text = loc.address;
    });
    if (homeController.pickupLocation.value != null) {
      pickupAddressController.text = homeController.pickupLocation.value!.address;
    }

    // Sync Drop-off Address
    ever(homeController.destinationLocation, (loc) {
      if (loc != null) dropoffAddressController.text = loc.address;
    });
    if (homeController.destinationLocation.value != null) {
      dropoffAddressController.text = homeController.destinationLocation.value!.address;
    }

    senderNameController.text = 'John Doe';
    senderPhoneController.text = '+2348012345678';
    receiverNameController.text = 'Jane Smith';
    receiverPhoneController.text = '+2348098765432';
    packageTypeController.text = 'Electronics';
    weightController.text = '2.5kg';
    dimensionsController.text = '30x20x10cm';
  }

  @override
  void onClose() {
    pickupAddressController.dispose();
    dropoffAddressController.dispose();
    senderNameController.dispose();
    senderPhoneController.dispose();
    receiverNameController.dispose();
    receiverPhoneController.dispose();
    packageTypeController.dispose();
    weightController.dispose();
    dimensionsController.dispose();
    notesController.dispose();
    super.onClose();
  }

  void setMatchingMode(MatchingMode? value) {
    if (value == null) return;
    matchingMode.value = value;
  }

  void setPaymentMode(PaymentMode? value) {
    if (value == null) return;
    paymentMode.value = value;
  }

  Future<void> createDeliveryJob() async {
    final pickupAddress = pickupAddressController.text.trim();
    final dropoffAddress = dropoffAddressController.text.trim();
    final senderName = senderNameController.text.trim();
    final senderPhone = senderPhoneController.text.trim();
    final receiverName = receiverNameController.text.trim();
    final receiverPhone = receiverPhoneController.text.trim();
    final packageType = packageTypeController.text.trim();
    final weight = weightController.text.trim();
    final dimensions = dimensionsController.text.trim();
    final notes = notesController.text.trim();

    final validationMessage = _validate(
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      senderName: senderName,
      senderPhone: senderPhone,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      packageType: packageType,
      weight: weight,
    );

    if (validationMessage != null) {
      Get.snackbar('Missing Details', validationMessage);
      return;
    }

    isSubmitting.value = true;

    try {
      final homeController = Get.find<HomeController>();
      final pickup = homeController.pickupLocation.value;
      final dropoff = homeController.destinationLocation.value;

      final job = await _customerApi.createJob(
        type: JobType.delivery,
        pickupLat: pickup?.lat ?? 6.5244,
        pickupLng: pickup?.lng ?? 3.3792,
        pickupAddress: pickupAddress,
        dropoffLat: dropoff?.lat ?? 6.4589,
        dropoffLng: dropoff?.lng ?? 3.6015,
        dropoffAddress: dropoffAddress,
        packageDetails: {
          'senderName': senderName,
          'senderPhone': senderPhone,
          'receiverName': receiverName,
          'receiverPhone': receiverPhone,
          'packageType': packageType,
          'weight': weight,
          if (notes.isNotEmpty) 'notes': notes,
          if (dimensions.isNotEmpty) 'dimensions': dimensions,
        },
        matchingMode: matchingMode.value,
        paymentMode: paymentMode.value,
        currency: 'NGN',
      );

      latestJob.value = job;
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().refreshHomeData(silent: true);
      }

      final summary = job.estimatedPrice != null
          ? 'Estimated fare: ${formatMajorAmount(job.estimatedPrice!, job.currency)}'
          : 'Delivery request submitted successfully.';
      Get.snackbar('Delivery Created', summary);
      Get.toNamed('/tracking?jobId=${job.id}', arguments: job.toJson());
    } catch (error) {
      Get.snackbar(
        'Unable to Create Delivery',
        _readableErrorMessage(
          error,
          fallback: 'Please review the delivery details and try again.',
        ),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  String? _validate({
    required String pickupAddress,
    required String dropoffAddress,
    required String senderName,
    required String senderPhone,
    required String receiverName,
    required String receiverPhone,
    required String packageType,
    required String weight,
  }) {
    if (pickupAddress.isEmpty) return 'Enter the pickup address.';
    if (dropoffAddress.isEmpty) return 'Enter the drop-off address.';
    if (senderName.isEmpty) return 'Enter the sender name.';
    if (senderPhone.isEmpty) return 'Enter the sender phone number.';
    if (receiverName.isEmpty) return 'Enter the receiver name.';
    if (receiverPhone.isEmpty) return 'Enter the receiver phone number.';
    if (packageType.isEmpty) return 'Enter the package type.';
    if (weight.isEmpty) return 'Enter the package weight.';
    return null;
  }

  String formatMinorAmount(int amount, String currency) {
    final major = (amount / 100).toStringAsFixed(2);
    if (currency.toUpperCase() == 'NGN') {
      return 'NGN $major';
    }
    return '$currency $major';
  }

  String formatMajorAmount(int amount, String currency) {
    final major = (amount).toStringAsFixed(2);
    return '$currency $major';
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

        if (message is List) {
          final combined = message
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .join('\n');
          if (combined.isNotEmpty) {
            return combined;
          }
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
