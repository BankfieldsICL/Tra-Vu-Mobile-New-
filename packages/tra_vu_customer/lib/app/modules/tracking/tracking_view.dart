import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tra_vu_core/models/job_status.dart';
import 'package:tra_vu_core/models/shared_models.dart';
import 'tracking_controller.dart';

class TrackingView extends GetView<TrackingController> {
  const TrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          Obx(() {
            final job = controller.currentJob.value;
            final center = job != null
                ? LatLng(job.pickupLocation.lat, job.pickupLocation.lng)
                : controller.driverLocation.value;

            // Build marker list
            final markers = <Marker>[
              // Driver marker (blue)
              Marker(
                point: controller.driverLocation.value,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Color(0xFF2563EB),
                  size: 34,
                ),
              ),
            ];

            if (job != null) {
              // Pickup marker (red)
              markers.add(Marker(
                point: LatLng(
                  job.pickupLocation.lat,
                  job.pickupLocation.lng,
                ),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFDC2626),
                  size: 36,
                ),
              ));

              // Dropoff marker (green)
              if (job.dropoffLocation != null) {
                markers.add(Marker(
                  point: LatLng(
                    job.dropoffLocation!.lat,
                    job.dropoffLocation!.lng,
                  ),
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Color(0xFF059669),
                    size: 36,
                  ),
                ));
              }
            }

            return FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.travu.customer',
                  maxNativeZoom: 19,
                ),
                MarkerLayer(markers: markers),
              ],
            );
          }),

          // ── Back button ──────────────────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.arrow_back),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ),

          // ── Bottom info sheet ────────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.22,
            maxChildSize: 0.62,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Obx(() {
                        final job = controller.currentJob.value;
                        final headline = job == null
                            ? controller.currentStatus.value.displayName
                            : '${job.type.displayName} • ${controller.currentStatus.value.displayName}';
                        return Text(
                          headline,
                          style: Get.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      Obx(
                        () => LinearProgressIndicator(
                          value: controller.currentStatus.value.progressValue,
                          backgroundColor: Colors.grey[200],
                          color: Colors.blueAccent,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Obx(() {
                        final job = controller.currentJob.value;
                        final driver = job?.driver;
                        final packageDetails = job?.packageDetails;
                        final status = controller.currentStatus.value;
                        final driverName = driver?.user != null
                            ? '${driver!.user!.firstName} ${driver.user!.lastName}'
                                  .trim()
                            : null;
                        final title = driverName ??
                            packageDetails?['receiverName']?.toString() ??
                            'Ride request';
                        final subtitle = driver != null
                            ? 'Driver assigned'
                            : _statusSubtitle(job?.matchingMode, status);

                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFE2E8F0),
                              child: Text(
                                title.isNotEmpty ? title[0].toUpperCase() : 'D',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone),
                              onPressed: driver != null ? () {} : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat),
                              onPressed: driver != null ? () {} : null,
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 20),
                      Obx(() {
                        final job = controller.currentJob.value;
                        final pickupAddress =
                            job?.pickupLocation.address ?? 'Loading pickup...';
                        final dropoffAddress =
                            job?.dropoffLocation?.address ??
                            'Loading drop-off...';
                        final estimate = job?.estimatedPrice != null
                            ? _formatMinorAmount(
                                job!.estimatedPrice!,
                                job.currency,
                              )
                            : 'Pending';
                        final packageType =
                            job?.packageDetails?['packageType']?.toString() ??
                            job?.packageDetails?['description']?.toString() ??
                            'Package';
                        final weight =
                            job?.packageDetails?['weight']?.toString() ??
                            'Not set';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Job details",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Pickup: $pickupAddress',
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Drop-off: $dropoffAddress',
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Package: $packageType • $weight',
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Estimate: $estimate • Payment: ${job?.paymentMode.displayName ?? 'Loading'}',
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatMinorAmount(int amount, String currency) {
    final major = (amount / 100).toStringAsFixed(2);
    return '${currency.toUpperCase()} $major';
  }

  String _statusSubtitle(MatchingMode? matchingMode, JobStatus status) {
    if (matchingMode == MatchingMode.negotiated &&
        status == JobStatus.matched) {
      return 'A driver bid has arrived';
    }

    switch (status) {
      case JobStatus.matched:
        return 'Driver found';
      case JobStatus.accepted:
        return 'Driver confirmed';
      case JobStatus.created:
        return matchingMode == MatchingMode.negotiated
            ? 'Waiting for driver bids'
            : 'Finding a nearby driver';
      default:
        return 'Tracking ride updates';
    }
  }
}
