import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tra_vu_core/models/models.dart';
import 'package:tra_vu_driver/app/modules/dispatch/widgets/trip_members_sheet.dart';
import 'package:tra_vu_driver/app/modules/dispatch/widgets/create_trip_bottom_sheet.dart';
import 'package:vynemit_flutter/vynemit_flutter.dart';

import '../../utils/currency_format.dart';
import 'dispatch_controller.dart';

class DispatchView extends GetView<DispatchController> {
  const DispatchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(6.5244, 3.3792), // Lagos
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.travu.driver',
                maxNativeZoom: 19,
              ),
            ],
          ),

          // ── Top bar ───────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: const Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                color: Colors.blueAccent,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tra-Vu Driver',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: NotificationBadge(
                            child: IconButton(
                              icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Color(0xFF64748B)),
                              onPressed: () =>
                                  _openNotificationCenter(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                        Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: controller.toggleOnlineStatus,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: controller.isOnline.value
                                        ? Colors.green
                                        : Colors.grey[700],
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        controller.isOnline.value
                                            ? Icons.wifi
                                            : Icons.wifi_off,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        controller.isOnline.value
                                            ? 'Online'
                                            : 'Offline',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          controller.socketStatus.value ==
                                              'Connected'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    controller.socketStatus.value,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          controller.socketStatus.value ==
                                              'Connected'
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome back, ${controller.driverName}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom sheet ─────────────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.34,
            minChildSize: 0.22,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: SafeArea(
                  top: false,
                  child: RefreshIndicator(
                    onRefresh: controller.refreshOverview,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                        Obx(
                          () => Text(
                            controller.isOnline.value
                                ? 'Driver console is live'
                                : 'Driver console is standing by',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            controller.statusMessage.value,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Obx(() {
                          return Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Today\'s earnings',
                                  value: controller.formattedTodayEarnings,
                                  tone: const Color(0xFF0F766E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  label: 'Completed trips',
                                  value:
                                      '${controller.completedTripsToday.value}',
                                  tone: const Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () => Get.bottomSheet(
                              CreateTripBottomSheet(controller: controller),
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                            ),
                            icon: const Icon(Icons.add_road_rounded),
                            label: const Text(
                              'INITIATE TRIP',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          if (controller.myActiveTrips.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Active Carpool Trips',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...controller.myActiveTrips.map(
                                (trip) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: Colors.green
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Icon(Icons.groups,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              trip.route.end.address,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              "Departs ${trip.departureTime.hour}:${trip.departureTime.minute.toString().padLeft(2, '0')} • ${trip.availableSeats} Seats left",
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Get.bottomSheet(
                                          TripMembersBottomSheet(
                                            trip: trip,
                                            members: controller
                                                    .tripMembers[trip.id] ??
                                                [],
                                            controller: controller,
                                          ),
                                        ),
                                        child: const Text("MANAGE"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        }),
                        Obx(() {
                          final offer = controller.activeJobOffer.value;
                          if (offer == null) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Incoming offer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(offer.pickupLocation.address),
                                const SizedBox(height: 4),
                                Text(
                                  offer.dropoffLocation?.address ??
                                      'Dropoff details coming in from dispatch',
                                  style:
                                      const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        const Text(
                          'Recent jobs',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          if (controller.isLoadingOverview.value) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          }
                          if (controller.recentJobs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Text(
                                'No completed or assigned jobs yet. Once you go online, new rides will appear here.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            );
                          }
                          return Column(
                            children: controller.recentJobs
                                .map((job) => _JobTile(job: job))
                                .toList(),
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

  void _openNotificationCenter(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
              const Expanded(
                child: NotificationList(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(
            value,
            softWrap: true,
            style: TextStyle(
              color: tone,
              fontWeight: FontWeight.bold,
              fontSize: value.contains('\n') ? 18 : 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});

  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final price = amountFromMinorUnits(job.finalPrice ?? job.estimatedPrice);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _statusColor(job.status).withValues(alpha: 0.12),
            child: Icon(
              job.type.name == 'delivery'
                  ? Icons.local_shipping_outlined
                  : Icons.route,
              color: _statusColor(job.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.pickupLocation.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  job.dropoffLocation?.address ?? 'Dropoff not provided',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrencyAmount(price, currencyCode: job.currency),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                job.status.displayName,
                style: TextStyle(
                  color: _statusColor(job.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.completed:
        return const Color(0xFF0F766E);
      case JobStatus.in_progress:
      case JobStatus.arrived:
      case JobStatus.enroute:
      case JobStatus.accepted:
      case JobStatus.pending_payment:
        return const Color(0xFF1D4ED8);
      case JobStatus.cancelled:
        return const Color(0xFFB91C1C);
      case JobStatus.matched:
      case JobStatus.created:
        return const Color(0xFF475569);
    }
  }
}
