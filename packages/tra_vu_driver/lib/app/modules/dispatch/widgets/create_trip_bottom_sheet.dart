import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/models/models.dart';
import 'package:tra_vu_core/models/place_model.dart';
import '../dispatch_controller.dart';
import '../../../services/location_service.dart';
import 'location_search_overlay.dart';

class CreateTripBottomSheet extends StatefulWidget {
  final DispatchController controller;

  const CreateTripBottomSheet({super.key, required this.controller});

  @override
  State<CreateTripBottomSheet> createState() => _CreateTripBottomSheetState();
}

class _CreateTripBottomSheetState extends State<CreateTripBottomSheet> {
  // OsmLocationService is no longer needed here — Place data comes
  // directly from the search overlay callback.

  int _totalSeats = 4;
  TimeOfDay _departureTime = TimeOfDay.now();
  LocationModel? _startLocation;
  LocationModel? _endLocation;
  final List<LocationModel> _waypoints = [];
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
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
              const SizedBox(height: 24),
              const Text(
                'Initiate Carpool Trip',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Provide trip details so customers can join you.',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 32),
              
              // Seats and Time Row
              Row(
                children: [
                  Expanded(
                    child: _InfoSection(
                      label: 'Available Seats',
                      value: '$_totalSeats Seats',
                      icon: Icons.groups_rounded,
                      onTap: () => _showSeatPicker(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _InfoSection(
                      label: 'Departure Time',
                      value: _departureTime.format(context),
                      icon: Icons.access_time_filled_rounded,
                      onTap: () => _showTimePicker(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Route Section
              const Text(
                'ROUTE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              
              _LocationTile(
                label: 'Start Location',
                location: _startLocation,
                icon: Icons.my_location_rounded,
                iconColor: Colors.blueAccent,
                onTap: () => _pickLocation(isStart: true),
              ),
              
              if (_waypoints.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._waypoints.asMap().entries.map((entry) {
                  final index = entry.key;
                  final waypoint = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LocationTile(
                      label: 'Stop ${index + 1}',
                      location: waypoint,
                      icon: Icons.pause_circle_filled_rounded,
                      iconColor: Colors.orange,
                      onDelete: () => setState(() => _waypoints.removeAt(index)),
                      onTap: () => _pickLocation(isWaypoint: true, waypointIndex: index),
                    ),
                  );
                }),
              ],
              
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _pickLocation(isWaypoint: true),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: const Text('Add stop'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                  padding: EdgeInsets.zero,
                ),
              ),
              
              const SizedBox(height: 8),
              _LocationTile(
                label: 'Destination',
                location: _endLocation,
                icon: Icons.location_on_rounded,
                iconColor: Colors.redAccent,
                onTap: () => _pickLocation(isEnd: true),
              ),
              
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _isCreating || _startLocation == null || _endLocation == null
                    ? null
                    : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Carpool Green
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade200,
                ),
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'CREATE TRIP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSeatPicker() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Select Available Seats',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...List.generate(6, (index) => index + 1).map((seats) => ListTile(
              title: Text('$seats Seats'),
              onTap: () {
                setState(() => _totalSeats = seats);
                Get.back();
              },
              trailing: _totalSeats == seats ? const Icon(Icons.check, color: Colors.green) : null,
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _departureTime,
    );
    if (pickedTime != null) {
      setState(() => _departureTime = pickedTime);
    }
  }

  void _pickLocation({bool isStart = false, bool isEnd = false, bool isWaypoint = false, int? waypointIndex}) {
    String title = 'Select Location';
    if (isStart) title = 'Starting Point';
    if (isEnd) title = 'Destination';
    if (isWaypoint) title = 'Add Stop';

    Get.bottomSheet(
      LocationSearchOverlay(
        title: title,
        hint: 'Search for address...',
        onPlaceSelected: (Place place) {
          final details = OsmLocationService.placeToLocationModel(place);
          setState(() {
            if (isStart) _startLocation = details;
            if (isEnd) _endLocation = details;
            if (isWaypoint) {
              if (waypointIndex != null) {
                _waypoints[waypointIndex] = details;
              } else {
                _waypoints.add(details);
              }
            }
          });
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _handleCreate() async {
    setState(() => _isCreating = true);
    
    final departureDate = DateTime.now();
    final actualDepartureTime = DateTime(
      departureDate.year,
      departureDate.month,
      departureDate.day,
      _departureTime.hour,
      _departureTime.minute,
    );

    final success = await widget.controller.createTrip(
      totalSeats: _totalSeats,
      departureTime: actualDepartureTime,
      start: _startLocation!,
      end: _endLocation!,
      waypoints: _waypoints,
    );

    setState(() => _isCreating = false);
    if (success) {
      Get.back();
      Get.snackbar(
        'Trip Created',
        'Your trip is now live for customers to join.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }
}

class _InfoSection extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _InfoSection({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final String label;
  final LocationModel? location;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _LocationTile({
    required this.label,
    this.location,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: location == null ? const Color(0xFFE2E8F0) : iconColor.withValues(alpha: 0.3),
            width: location == null ? 1 : 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location?.address ?? 'Tap to select location',
                    style: TextStyle(
                      fontSize: 14,
                      color: location == null ? Colors.grey : Colors.black87,
                      fontWeight: location == null ? FontWeight.normal : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
