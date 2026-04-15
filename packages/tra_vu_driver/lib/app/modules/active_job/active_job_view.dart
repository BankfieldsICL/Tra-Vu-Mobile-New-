import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/models/job_status.dart';

import 'active_job_controller.dart';
import 'widgets/lifecycle_slider.dart';

class ActiveJobView extends GetView<ActiveJobController> {
  const ActiveJobView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          Obx(() => FlutterMap(
                mapController: controller.mapController,
                options: MapOptions(
                  initialCenter: controller.driverLocation.value,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.travu.driver',
                    maxNativeZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      // Driver marker (blue car)
                      Marker(
                        point: controller.driverLocation.value,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Color(0xFF2563EB),
                          size: 38,
                        ),
                      ),
                      // Customer / destination marker (red)
                      Marker(
                        point: controller.customerLocation.value,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFFDC2626),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              )),

          // ── Status pill ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            color: Colors.blueAccent,
                            size: 10,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            controller.status.value.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom sheet ─────────────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.34,
            minChildSize: 0.24,
            maxChildSize: 0.56,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        // Customer info row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFE2E8F0),
                              child: Text(
                                controller.customerInitial,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rider',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    controller.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_outlined),
                              onPressed: controller.customerPhone.isEmpty
                                  ? null
                                  : () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _InfoRow(
                          icon: Icons.my_location,
                          label: 'Pickup',
                          value: controller.pickupAddress,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.flag_outlined,
                          label: 'Dropoff',
                          value: controller.dropoffAddress,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.payments_outlined,
                          label: 'Estimated earnings',
                          value: controller.earningsLabel,
                        ),
                        const SizedBox(height: 20),
                        Obx(() {
                          final isDone =
                              controller.status.value == JobStatus.completed;
                          if (isDone) return const SizedBox.shrink();
                          return LifecycleSlider(
                            label: controller.sliderLabel,
                            color: _sliderColor(controller.status.value),
                            onSlideComplete: controller.advanceStatus,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _sliderColor(JobStatus status) {
    switch (status) {
      case JobStatus.in_progress:
        return Colors.green;
      case JobStatus.arrived:
        return Colors.orangeAccent;
      default:
        return Colors.blueAccent;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
