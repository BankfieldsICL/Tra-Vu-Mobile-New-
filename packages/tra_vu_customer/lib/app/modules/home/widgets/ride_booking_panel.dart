import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/models/job_status.dart';
import 'package:tra_vu_core/models/shared_models.dart';
import 'package:tra_vu_core/widgets/tra_vu_select.dart';

import '../home_controller.dart';
import '../ride_booking_controller.dart';
import 'location_search_overlay.dart';

class RideBookingPanel extends GetView<RideBookingController> {
  const RideBookingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Where to?",
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Request an instant ride or collect bids from nearby drivers.",
            style: Get.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 16),
          _buildAddressField(
            hint: "Pickup Location",
            icon: Icons.my_location_rounded,
            isDestination: false,
          ),
          const SizedBox(height: 8),
          _buildAddressField(
            hint: "Search Destination",
            icon: Icons.search,
            isDestination: true,
          ),
          const SizedBox(height: 16),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildVehicleClass("Economy", "Best value"),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVehicleClass("Premium", "Extra comfort"),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVehicleClass("XL", "More room"),
                ),
              ],
            ),
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
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest ride request',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Status: ${job.status.displayName} • Estimate: $summary',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF1D4ED8),
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
                  : controller.createRideJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
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
                  : Text(
                      controller.matchingMode.value == MatchingMode.negotiated
                          ? "Request Bids"
                          : "Request Ride",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField({
    required String hint,
    required IconData icon,
    required bool isDestination,
  }) {
    return Obx(() {
      final homeController = Get.find<HomeController>();
      final location = isDestination
          ? homeController.destinationLocation.value
          : homeController.pickupLocation.value;

      return TextField(
        readOnly: true,
        controller: TextEditingController(text: location?.address ?? ""),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
          filled: true,
          fillColor: const Color(0xFFF2F4F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onTap: () {
          Get.bottomSheet(
            LocationSearchOverlay(isDestination: isDestination),
            isScrollControlled: true,
          );
        },
      );
    });
  }

  Widget _buildVehicleClass(String title, String subtitle) {
    final isSelected = controller.selectedVehicle.value == title;

    return GestureDetector(
      onTap: () => controller.setVehicle(title),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.directions_car),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
