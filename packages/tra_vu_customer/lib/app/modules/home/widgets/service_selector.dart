import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home_controller.dart';

class ServiceSelector extends StatelessWidget {
  final HomeController controller;

  const ServiceSelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Obx(() {
        final activeType = controller.activeService.value;
        return Row(
          children: ServiceType.values.map((type) {
            final isActive = type == activeType;
            final color = _getServiceColor(type);
            
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.switchService(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getServiceIcon(type),
                        size: 20,
                        color: isActive ? color : const Color(0xFF667085),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getServiceLabel(type),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          color: isActive ? const Color(0xFF101828) : const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  IconData _getServiceIcon(ServiceType type) {
    switch (type) {
      case ServiceType.rideHailing:
        return Icons.directions_car_rounded;
      case ServiceType.carpooling:
        return Icons.groups_rounded;
      case ServiceType.packageDelivery:
        return Icons.local_shipping_rounded;
    }
  }

  String _getServiceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.rideHailing:
        return 'Ride';
      case ServiceType.carpooling:
        return 'Carpool';
      case ServiceType.packageDelivery:
        return 'Delivery';
    }
  }

  Color _getServiceColor(ServiceType type) {
    switch (type) {
      case ServiceType.rideHailing:
        return const Color(0xFF2563EB);
      case ServiceType.carpooling:
        return const Color(0xFF059669);
      case ServiceType.packageDelivery:
        return const Color(0xFFF97316);
    }
  }
}
