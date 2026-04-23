import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/models/job_status.dart';
import 'package:tra_vu_core/models/shared_models.dart';
import 'package:tra_vu_core/widgets/tra_vu_select.dart';
import '../delivery_booking_controller.dart';
import 'location_search_overlay.dart';

class DeliveryBookingPanel extends GetView<DeliveryBookingController> {
  const DeliveryBookingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Send a Package",
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create a delivery request with sender, receiver, and package details.",
            style: Get.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 16),
          _inputBox(
            "Pickup Address",
            Icons.pin_drop_rounded,
            controller.pickupAddressController,
            onTap: () => Get.bottomSheet(
              const LocationSearchOverlay(isDestination: false),
              isScrollControlled: true,
            ),
          ),
          const SizedBox(height: 8),
          _inputBox(
            "Drop-off Address",
            Icons.flag_rounded,
            controller.dropoffAddressController,
            onTap: () => Get.bottomSheet(
              const LocationSearchOverlay(isDestination: true),
              isScrollControlled: true,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _inputBox(
                  "Sender Name",
                  Icons.person_outline_rounded,
                  controller.senderNameController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _inputBox(
                  "Sender Phone",
                  Icons.phone_outlined,
                  controller.senderPhoneController,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _inputBox(
                  "Receiver Name",
                  Icons.person_2_outlined,
                  controller.receiverNameController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _inputBox(
                  "Receiver Phone",
                  Icons.phone_callback_outlined,
                  controller.receiverPhoneController,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _inputBox(
                  "Package Type",
                  Icons.inventory_2_outlined,
                  controller.packageTypeController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _inputBox(
                  "Weight",
                  Icons.scale_outlined,
                  controller.weightController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _inputBox(
            "Dimensions",
            Icons.straighten_rounded,
            controller.dimensionsController,
          ),
          const SizedBox(height: 8),
          _inputBox(
            "Delivery Notes",
            Icons.sticky_note_2_outlined,
            controller.notesController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Obx(
            () => TraVuSelect<MatchingMode>(
              label: 'Matching Mode',
              hint: 'Choose matching mode',
              value: controller.matchingMode.value,
              items: MatchingMode.values,
              itemAsString: (mode) => mode.displayName,
              prefixIcon: Icons.flash_on_rounded,
              onChanged: controller.setMatchingMode,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TraVuSelect<PaymentMode>(
              label: 'Payment Mode',
              hint: 'Choose payment mode',
              value: controller.paymentMode.value,
              items: PaymentMode.values,
              itemAsString: (mode) => mode.displayName,
              prefixIcon: Icons.account_balance_wallet_outlined,
              onChanged: controller.setPaymentMode,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final job = controller.latestJob.value;
            if (job == null) {
              return const SizedBox.shrink();
            }

            final summary = job.estimatedPrice != null
                ? controller.formatMajorAmount(
                    job.estimatedPrice!,
                    job.currency,
                  )
                : 'Pending pricing';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest delivery request',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Status: ${job.status.displayName} • Estimate: $summary',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.createDeliveryJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Request Delivery",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBox(
    String hint,
    IconData icon,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: onTap != null,
      onTap: onTap,
      decoration: _decoration(label: hint, icon: icon),
    );
  }

  InputDecoration _decoration({required String label, required IconData icon}) {
    return InputDecoration(
      hintText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
