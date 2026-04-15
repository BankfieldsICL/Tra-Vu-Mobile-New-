import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/services/auth_service.dart';

import '../controllers/driver_auth_controller.dart';

class DriverAuthGateView extends StatefulWidget {
  const DriverAuthGateView({super.key});

  @override
  State<DriverAuthGateView> createState() => _DriverAuthGateViewState();
}

class _DriverAuthGateViewState extends State<DriverAuthGateView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      return;
    }

    final authService = Get.find<AuthService>();
    final hasValidSession = await authService.restoreAndValidateSession(
      force: true,
    );
    if (!mounted) {
      return;
    }

    if (!hasValidSession || !authService.isAuthenticated.value) {
      Get.offAllNamed('/login');
      return;
    }

    final controller = Get.isRegistered<DriverAuthController>()
        ? Get.find<DriverAuthController>()
        : Get.put(DriverAuthController());

    await controller.continueAfterRestoredSession();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
