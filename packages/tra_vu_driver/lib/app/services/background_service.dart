import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static Future<void> initialize(dynamic Function(ServiceInstance) onStart) async {
    final service = FlutterBackgroundService();

    // Note: Notification Channel is now created natively in MainActivity.kt
    // for maximum stability on Android 14+

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'tra_vu_driver_tracking',
        initialNotificationTitle: 'Tra-Vu Driver',
        initialNotificationContent: 'Tracking location for dispatch...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: (service) async => true,
      ),
    );

    await service.startService();
  }
}
