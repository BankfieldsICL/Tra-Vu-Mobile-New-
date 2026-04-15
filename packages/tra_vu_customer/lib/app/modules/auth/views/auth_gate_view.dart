import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/config/api_config.dart';
import 'package:tra_vu_core/services/auth_service.dart';
import 'package:tra_vu_core/sockets/tracking_socket_service.dart';

class AuthGateView extends StatefulWidget {
  const AuthGateView({super.key});

  @override
  State<AuthGateView> createState() => _AuthGateViewState();
}

class _AuthGateViewState extends State<AuthGateView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    final authService = Get.find<AuthService>();
    final isAuthenticated = await authService.restoreAndValidateSession(
      force: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    if (isAuthenticated) {
      final token = authService.currentUserToken.value;
      if (token != null && token.isNotEmpty) {
        final socketService = Get.find<TrackingSocketService>();
        await socketService.init(ApiConfig.baseSocketUrl, token, ApiConfig.tenantId);
      }
      Get.offAllNamed('/home');
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
