import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/tra_vu_core.dart';
import 'package:intl/intl.dart';

import 'history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Request History',
          style: TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF344054), size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF344054)),
            onPressed: controller.loadJobs,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return _buildErrorState();
        }

        if (controller.jobs.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.loadJobs,
          color: const Color(0xFF2563EB),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: controller.jobs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final job = controller.jobs[index];
              return _JobHistoryCard(job: job, controller: controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 48,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your previous requests will appear here\nonce you've made your first booking.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Get.offAllNamed('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              controller.error.value!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: controller.loadJobs,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobHistoryCard extends StatelessWidget {
  final JobModel job;
  final HistoryController controller;

  const _JobHistoryCard({required this.job, required this.controller});

  @override
  Widget build(BuildContext context) {
    final canTrack = job.status != JobStatus.completed &&
        job.status != JobStatus.cancelled;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _statusColor(job.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _serviceIcon(job.type),
                        color: Color(job.status.statusColorValue),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.type.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101828),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d, yyyy • h:mm a')
                                .format(job.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: job.status),
                  ],
                ),
                const SizedBox(height: 16),
                _LocationRow(
                  icon: Icons.circle_outlined,
                  color: Colors.blueAccent,
                  address: job.pickupLocation.address,
                  isLast: false,
                ),
                const SizedBox(height: 12),
                _LocationRow(
                  icon: Icons.location_on_rounded,
                  color: Colors.redAccent,
                  address: job.dropoffLocation?.address ?? 'Dropoff pending',
                  isLast: true,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.formatPrice(
                      job.finalPrice ?? job.estimatedPrice, job.currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                    fontSize: 16,
                  ),
                ),
                if (canTrack)
                  TextButton.icon(
                    onPressed: () => controller.trackJob(job),
                    icon: const Icon(Icons.my_location_rounded, size: 16),
                    label: const Text('Track'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () {
                      // Logic for re-booking or viewing details could go here
                      Get.snackbar('Job Details',
                          'Viewing details for ${job.id.substring(0, 8)}');
                    },
                    child: const Text(
                      'Details',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _serviceIcon(JobType type) {
    switch (type) {
      case JobType.carpool:
        return Icons.group_rounded;
      case JobType.delivery:
        return Icons.local_shipping_outlined;
      case JobType.ride:
        return Icons.directions_car_rounded;
      default:
        return Icons.more_horiz;
    }
  }

  Color _statusColor(JobStatus status) {
    return Color(status.statusColorValue);
  }
}

class _StatusBadge extends StatelessWidget {
  final JobStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = Color(status.statusColorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String address;
  final bool isLast;

  const _LocationRow({
    required this.icon,
    required this.color,
    required this.address,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: color, size: 18),
            if (!isLast)
              Container(
                width: 1,
                height: 20,
                color: const Color(0xFFD0D5DD),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF344054),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
