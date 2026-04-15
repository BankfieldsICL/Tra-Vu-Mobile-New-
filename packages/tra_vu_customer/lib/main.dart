import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/tra_vu_core.dart';
import 'package:tra_vu_core/config/api_config.dart';
import 'package:tra_vu_customer/app/modules/auth/views/auth_gate_view.dart';

import 'app/modules/home/home_view.dart';
import 'app/modules/home/home_controller.dart';
import 'app/modules/home/delivery_booking_controller.dart';
import 'app/modules/home/ride_booking_controller.dart';
import 'app/modules/tracking/tracking_view.dart';
import 'app/modules/tracking/tracking_controller.dart';
import 'app/modules/wallet/wallet_view.dart';
import 'app/modules/wallet/wallet_controller.dart';
import 'app/modules/auth/views/login_view.dart';
import 'app/modules/auth/views/otp_view.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/services/location_service.dart';
import 'package:provider/provider.dart';
import 'package:vynemit_flutter/vynemit_flutter.dart';

import 'app/modules/history/history_view.dart';
import 'app/modules/history/history_controller.dart';
import 'app/modules/profile/profile_view.dart';
import 'app/modules/profile/profile_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Core Services globally
  Get.put(TrackingSocketService());
  Get.put(AuthService());
  Get.put(OsmLocationService());

  final apiClient = Get.put(ApiClient());
  apiClient.init(
    baseUrl: ApiConfig.baseUrl,
    tenantId: ApiConfig.tenantId,
    apiKey: ApiConfig.apiKey,
  );

  // Initialize App-Specific APIs
  Get.put(CustomerApi());

  // Initialize Notification SDK
  final notificationConfig = NotificationConfig(
    apiUrl: "${ApiConfig.baseUrl}/v1",
    userId: Get.find<AuthService>().currentUserId.value ?? 'unknown',
    getAuthToken: () async => Get.find<AuthService>().currentUserToken.value ?? '',
    onRefreshAuth: () async => Get.find<AuthService>().refreshToken(),
    realtimeTransport: RealtimeTransport.websocket,
    wsUrl: ApiConfig.baseSocketUrl,
    debug: true,
    onDebugEvent: (event) => debugPrint("Vynemit Debug: $event"),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => VynemitProvider(notificationConfig),
      child: const CustomerApp(),
    ),
  );
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tra-Vu Customer',
      debugShowCheckedModeBanner: false,
      initialRoute: '/auth/gate',
      getPages: [
        GetPage(name: '/auth/gate', page: () => const AuthGateView()),
        GetPage(
          name: '/login',
          page: () => const LoginView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => AuthController());
          }),
        ),
        GetPage(
          name: '/auth/otp',
          page: () => const OtpVerificationView(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<AuthController>()) {
              Get.lazyPut(() => AuthController());
            }
          }),
        ),
        GetPage(
          name: '/home',
          page: () => const HomeView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => HomeController());
            Get.lazyPut(() => DeliveryBookingController());
            Get.lazyPut(() => RideBookingController());
          }),
        ),
        GetPage(
          name: '/tracking',
          page: () => const TrackingView(),
          binding: BindingsBuilder(() {
            final jobId = Get.parameters['id'] ?? 
                          Get.parameters['jobId'] ?? 
                          'Unknown Job';
            Get.lazyPut(() => TrackingController(jobId));
          }),
        ),
        GetPage(
          name: '/wallet',
          page: () => const WalletView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => WalletController());
          }),
        ),
        GetPage(
          name: '/history',
          page: () => const HistoryView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => HistoryController());
          }),
        ),
        GetPage(
          name: '/profile',
          page: () => const ProfileView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ProfileController());
          }),
        ),
      ],
    );
  }
}
