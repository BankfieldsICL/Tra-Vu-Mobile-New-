import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tra_vu_core/tra_vu_core.dart';
import 'package:tra_vu_core/config/api_config.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'app/services/driver_location_service.dart';
import 'app/services/location_service.dart';

import 'app/modules/dispatch/dispatch_controller.dart';
import 'package:provider/provider.dart';
import 'package:vynemit_flutter/vynemit_flutter.dart';
import 'app/modules/dispatch/dispatch_view.dart';
import 'app/modules/auth/views/auth_gate_view.dart';
import 'app/modules/auth/views/driver_login_view.dart';
import 'app/modules/auth/views/profile_completion_view.dart';
import 'app/modules/auth/views/document_verification_view.dart';
import 'app/modules/auth/controllers/driver_auth_controller.dart';
import 'app/modules/active_job/active_job_view.dart';
import 'app/modules/active_job/active_job_controller.dart';
import 'app/modules/earnings/trip_summary_view.dart';
import 'app/services/background_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  DartPluginRegistrant.ensureInitialized();
  debugPrint('--- BACKGROUND ISOLATE BOOTSTRAP (main.dart) ---');

  StreamSubscription<Position>? positionSubscription;
  io.Socket? socket;

  // Replaced by setAsBackground / setAsForeground listeners above

  service.on('startTracking').listen((event) async {
    final token = event?['token'] as String?;
    final baseUrl = event?['baseUrl'] as String?;
    final jobId = event?['jobId'] as String?;

    if (token == null || baseUrl == null) {
      debugPrint('Background Socket Error: Missing token or baseUrl');
      return;
    }

    await positionSubscription?.cancel();
    socket?.dispose();

    debugPrint('Background Socket: Initializing to $baseUrl');

    try {
      socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'tenantId': ApiConfig.tenantId})
            .setAuth({'token': token})
            .enableAutoConnect()
            .build(),
      );

      debugPrint('Background Socket: Handshaking with tenantId ${ApiConfig.tenantId}');

      socket!.onConnect((_) => debugPrint('Background Socket: Successfully Connected'));
      socket!.onDisconnect((_) => debugPrint('Background Socket: Disconnected'));
      socket!.onConnectError((err) => debugPrint('Background Socket Connect Error: $err'));
      socket!.onError((err) => debugPrint('Background Socket Error: $err'));

      positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((position) {
        if (socket?.connected == true) {
          socket!.emit('updateLocation', {
            'lat': position.latitude,
            'lng': position.longitude,
            if (jobId != null) 'jobId': jobId,
          });
          debugPrint('Background Socket: Emitted location (${position.latitude}, ${position.longitude})');
        }
      });

    } catch (e) {
      debugPrint('Background Isolate Setup Error: $e');
    }
  });

  service.on('stopTracking').listen((event) async {
    debugPrint('Background Socket: Received stopTracking');
    await positionSubscription?.cancel();
    positionSubscription = null;
    socket?.dispose();
    socket = null;
  });

  // Keep-alive status
  Timer.periodic(const Duration(seconds: 30), (timer) {
    service.invoke('update', {
      "current_date": DateTime.now().toIso8601String(),
      "tracking_active": positionSubscription != null,
      "socket_connected": socket?.connected ?? false,
    });
  });
}



// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   print('🔥 BACKGROUND SERVICE STARTED');

//   final socket = io.io(
//     ApiConfig.baseSocketUrl,
//     io.OptionBuilder()
//         .setTransports(['websocket'])
//         // .setPath('/tracking')
//         .enableAutoConnect()
//         .build(),
//   );

//   socket.onConnect((_) {
//     print('✅ SOCKET CONNECTED');
//   });

//   socket.onConnectError((err) {
//     print('❌ SOCKET CONNECT ERROR: $err');
//   });

//   socket.onError((err) {
//     print('❌ SOCKET ERROR: $err');
//   });

//   socket.onDisconnect((_) {
//     print('⚠️ SOCKET DISCONNECTED');
//   });

//   Geolocator.getPositionStream(
//     locationSettings: const LocationSettings(
//       accuracy: LocationAccuracy.high,
//       distanceFilter: 10,
//     ),
//   ).listen((position) {
//     print('📍 BG LOCATION: ${position.latitude}, ${position.longitude}');
//   });
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request mandatory permissions for background service on Android 13+
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  
  // Location permissions are mandatory for the foreground service type
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }

  await BackgroundService.initialize(onStart);

  // Register Essential Tracking Services
  Get.put(TrackingSocketService());
  Get.put(DriverLocationService());
  Get.put(OsmLocationService());

  // Register Core Services globally
  Get.put(AuthService());

  final apiClient = Get.put(ApiClient());
  apiClient.init(
    baseUrl: ApiConfig.baseUrl,
    tenantId: ApiConfig.tenantId,
    apiKey: ApiConfig.apiKey,
  );

  // Initialize App-Specific APIs
  Get.put(DriverApi());
  Get.put(DriverAuthController(), permanent: true);

  // Initialize Notification SDK
  final notificationConfig = NotificationConfig(
    apiUrl: "${ApiConfig.baseUrl}/v1",
    userId: Get.find<AuthService>().currentUserId.value ?? 'unknown',
    getAuthToken: () async => Get.find<AuthService>().currentUserToken.value ?? '',
    onRefreshAuth: () async => Get.find<AuthService>().refreshToken(),
    realtimeTransport: RealtimeTransport.websocket,
    wsUrl: ApiConfig.baseSocketUrl, // Derive WS URL from API URL
    debug: true,
    onDebugEvent: (event) => debugPrint("Vynemit Debug: $event"),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => VynemitProvider(notificationConfig),
      child: const DriverApp(),
    ),
  );
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tra-Vu Driver',
      initialRoute: '/auth/gate',
      debugShowCheckedModeBanner: false,
      getPages: [
        GetPage(name: '/auth/gate', page: () => const DriverAuthGateView()),
        GetPage(name: '/login', page: () => const DriverLoginView()),
        GetPage(
          name: '/auth/profile-details',
          page: () => const ProfileCompletionView(),
        ),
        GetPage(
          name: '/auth/documents',
          page: () => const DocumentVerificationView(),
        ),
        GetPage(
          name: '/dispatch',
          page: () => const DispatchView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => DispatchController());
          }),
        ),
        GetPage(
          name: '/active-trip',
          page: () => const ActiveJobView(),
          binding: BindingsBuilder(() {
            final args = Get.arguments as Map<String, dynamic>? ?? {};
            Get.lazyPut(
              () => ActiveJobController(
                jobId: args['id']?.toString() ??
                    args['jobId']?.toString() ??
                    'Unknown Job',
                jobOffer: args,
              ),
            );
          }),
        ),
        GetPage(name: '/trip-summary', page: () => const TripSummaryView()),
      ],
    );
  }
}
