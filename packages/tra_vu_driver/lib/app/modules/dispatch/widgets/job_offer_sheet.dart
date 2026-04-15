import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/models/job_model.dart';
import 'package:tra_vu_core/models/shared_models.dart';
import '../dispatch_controller.dart';

class JobOfferBottomSheet extends StatelessWidget {
  final JobModel offer;
  final DispatchController controller;

  const JobOfferBottomSheet({
    super.key,
    required this.offer,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDelivery = offer.type == JobType.delivery;
    final isCarpool = offer.type == JobType.carpool;
    final accentColor = isDelivery
        ? Colors.orangeAccent
        : isCarpool
            ? Colors.tealAccent
            : Colors.blueAccent;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.42,
        minChildSize: 0.3,
        maxChildSize: 0.75,
        builder: (context, scrollController) {
          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          isDelivery
                              ? Icons.local_shipping
                              : isCarpool
                                  ? Icons.groups
                                  : Icons.directions_car,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDelivery
                              ? "New Delivery"
                              : isCarpool
                                  ? "New Carpool Request"
                                  : "New Ride Request",
                          style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          offer.estimatedPrice != null
                              ? "\$${offer.estimatedPrice! / 100}"
                              : '',
                          style: Get.textTheme.titleLarge?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLocationRow(
                      Icons.my_location,
                      "Pickup",
                      offer.pickupLocation.address,
                    ),
                    const SizedBox(height: 8),
                    _buildLocationRow(
                      Icons.flag,
                      "Dropoff",
                      offer.dropoffLocation?.address ?? 'Unknown destination',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.declineOffer,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text("Decline"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: controller.isAcceptingOffer.value
                                  ? null
                                  : controller.acceptOffer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: controller.isAcceptingOffer.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Accept",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String title, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                address,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
