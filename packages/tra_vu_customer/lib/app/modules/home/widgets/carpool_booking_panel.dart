import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home_controller.dart';
import 'location_search_overlay.dart';

class CarpoolBookingPanel extends StatelessWidget {
  const CarpoolBookingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      // Container styling is handled by DraggableScrollableSheet parent
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Find a Shared Trip", style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Obx(() {
            final destination = Get.find<HomeController>().destinationLocation.value;
            return TextField(
              readOnly: true,
              controller: TextEditingController(text: destination?.address ?? ""),
              decoration: InputDecoration(
                hintText: "Enter Destination Route",
                prefixIcon: const Icon(Icons.route, color: Colors.green),
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
                  const LocationSearchOverlay(isDestination: true),
                  isScrollControlled: true,
                );
              },
            );
          }),
          const SizedBox(height: 16),
          
          Obx(() {
            if (Get.find<HomeController>().isLoadingTrips.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final trips = Get.find<HomeController>().availableTrips;
            if (trips.isEmpty) {
              return const Center(child: Text("No trips found matching your route."));
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trips.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: Colors.green),
                    ),
                    title: Text(
                      trip.driver?.user?.firstName != null 
                        ? "${trip.driver!.user!.firstName} matches your route"
                        : "Driver matches your route",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Departs ${trip.departureTime.hour}:${trip.departureTime.minute.toString().padLeft(2, '0')} • ${trip.availableSeats} Seats left",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => Get.find<HomeController>().joinTrip(trip),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text("Join"),
                    ),
                  ),
                );
              },
            );
          })
        ],
      ),
    );
  }
}
