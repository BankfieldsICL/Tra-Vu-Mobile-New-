import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tra_vu_core/models/shared_models.dart';
import 'package:tra_vu_core/services/auth_service.dart';
import 'package:tra_vu_customer/app/modules/home/widgets/trip_otp_sheet.dart';
import 'home_controller.dart';
import 'widgets/ride_booking_panel.dart';
import 'widgets/delivery_booking_panel.dart';
import 'widgets/carpool_booking_panel.dart';
import 'widgets/service_selector.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: const LatLng(6.5244, 3.3792),
              initialZoom: 13.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  controller.updatePickupFromMap(camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.travu.customer',
                maxNativeZoom: 19,
              ),
            ],
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _buildTopBar(context),
            ),
          ),

          // Center Pin for Pickup Selection
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Obx(() => Text(
                      controller.pickupLocation.value?.address ?? "Locating...",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    )),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.location_on_rounded, size: 40, color: Color(0xFF2563EB)),
                  const SizedBox(height: 34), // Offset for pin tip to align with center
                ],
              ),
            ),
          ),

          // Core Booking Dynamic Sheet Overlay
          SafeArea(
            child: DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.45,
              maxChildSize: 0.8,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                    return Container(
                      // margin: const EdgeInsets.only(bottom: 34),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            ServiceSelector(controller: controller),
                            Obx(() {
                              final type = controller.activeService.value;
                              Widget panel;
                              if (type == ServiceType.packageDelivery) {
                                panel = const DeliveryBookingPanel(
                                  key: ValueKey('delivery'),
                                );
                              } else if (type == ServiceType.carpooling) {
                                panel = const CarpoolBookingPanel(
                                  key: ValueKey('carpool'),
                                );
                              } else {
                                panel = const RideBookingPanel(
                                  key: ValueKey('ride'),
                                );
                              }

                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                child: panel,
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
            ),
          ),
          
          Positioned(
            left: 24,
            right: 24,
            top: 108,
            child: Obx(() {
              if (controller.myActiveTrips.isEmpty) {
                return const SizedBox.shrink();
              }

              final activeTrip = controller.myActiveTrips.first;
              final status = activeTrip.status;
              final isApproved = status == TripMemberStatus.approved;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 20,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.group, color: Colors.green, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Upcoming Carpool',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        _buildStatusChip(status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activeTrip.trip?.route.end.address ?? "Trip Destination",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    if (isApproved)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.bottomSheet(
                            TripOTPSheet(membership: activeTrip),
                          ),
                          icon: const Icon(Icons.vpn_key_outlined, size: 18),
                          label: const Text("Show Boarding OTP"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF101828),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    else
                      const Text(
                        "Waiting for driver approval...",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange, fontSize: 12),
                      ),
                  ],
                ),
              );
            }),
          ),
        
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final authService = Get.find<AuthService>();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Obx(() {
        final headline = controller.isLoading.value
            ? 'Loading your account'
            : 'Welcome, ${controller.displayName}';

        final balance = controller.walletBalance.value;
        final currency = controller.walletCurrency.value;
        final isVisible = controller.isBalanceVisible.value;

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF101828),
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => controller.isBalanceVisible.toggle(),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isVisible
                              ? _formatBalance(balance, currency)
                              : '••••••••',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF667085),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: isVisible ? 0 : 2,
                                  ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 14,
                          color: const Color(0xFF98A2B3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildKebabMenu(context, authService),
          ],
        );
      }),
    );
  }

  String _formatBalance(double amount, String currency) {
    final symbol = currency == 'NGN' ? '₦' : '\$';
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  Widget _buildKebabMenu(BuildContext context, AuthService authService) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475467)),
      elevation: 10,
      offset: const Offset(0, 50),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        switch (value) {
          case 'wallet':
            Get.toNamed('/wallet');
            break;
          case 'profile':
            Get.toNamed('/profile');
            break;
          case 'history':
            Get.toNamed('/history');
            break;
          case 'support':
            Get.snackbar('Support', 'Connecting you to Tra-Vu chat support.');
            break;
          case 'settings':
            Get.snackbar('Settings', 'User preferences loading...');
            break;
          case 'logout':
            authService.logout();
            break;
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem('profile', Icons.person_outline, 'Update Profile'),
        _buildPopupItem('wallet', Icons.account_balance_wallet_outlined, 'My Wallet'),
        _buildPopupItem('history', Icons.history_rounded, 'Request History'),
        _buildPopupItem('support', Icons.support_agent_rounded, 'Support'),
        _buildPopupItem('settings', Icons.settings_outlined, 'Settings'),
        const PopupMenuDivider(),
        _buildPopupItem('logout', Icons.logout_rounded, 'Log out', isDestructive: true),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      String value, IconData icon, String label,
      {bool isDestructive = false}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: isDestructive ? const Color(0xFFD92D20) : const Color(0xFF344054)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDestructive ? const Color(0xFFD92D20) : const Color(0xFF101828),
            ),
          ),
        ],
      ),
    );
  }

  Color _serviceColor(ServiceType type) {
    switch (type) {
      case ServiceType.rideHailing:
        return const Color(0xFF2563EB);
      case ServiceType.carpooling:
        return const Color(0xFF059669);
      case ServiceType.packageDelivery:
        return const Color(0xFFF97316);
    }
  }

  String _formatMinorAmount(int amount, String currency) {
    final major = (amount / 100).toStringAsFixed(2);
    return '${currency.toUpperCase()} $major';
  }

  Widget _buildStatusChip(TripMemberStatus status) {
    Color color;
    switch (status) {
      case TripMemberStatus.approved:
        color = Colors.green;
        break;
      case TripMemberStatus.pending:
        color = Colors.orange;
        break;
      case TripMemberStatus.rejected:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
