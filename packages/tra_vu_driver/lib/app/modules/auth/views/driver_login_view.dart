import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/driver_auth_controller.dart';

class DriverLoginView extends GetView<DriverAuthController> {
  const DriverLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D1B2A),
                  Color(0xFF1B263B),
                  Color(0xFF415A77),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -40,
            child: _GlowOrb(
              color: const Color(0xFF778DA9).withValues(alpha: 0.18),
              size: 220,
            ),
          ),
          Positioned(
            bottom: -80,
            left: -30,
            child: _GlowOrb(
              color: const Color(0xFF415A77).withValues(alpha: 0.2),
              size: 260,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tra-Vu Driver',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Fast onboarding for drivers, then vehicle and license setup after verification.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Obx(() {
                          final otpRequested = controller.otpRequested.value;
                          final isSignupMode = controller.isSignupMode;
                          final isPhoneFlow = controller.isPhoneFlow;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!otpRequested) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ModeChip(
                                        label: 'Sign in',
                                        isSelected: !isSignupMode,
                                        onTap: () => controller.setMode(
                                          DriverAuthMode.signIn,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ModeChip(
                                        label: 'Create account',
                                        isSelected: isSignupMode,
                                        onTap: () => controller.setMode(
                                          DriverAuthMode.signUp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ModeChip(
                                        label: 'Phone',
                                        isSelected: isPhoneFlow,
                                        onTap: () => controller.setInputMethod(
                                          AuthInputMethod.phone,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ModeChip(
                                        label: 'Email',
                                        isSelected: !isPhoneFlow,
                                        onTap: () => controller.setInputMethod(
                                          AuthInputMethod.email,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                              ],
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        isPhoneFlow
                                            ? Icons.phone_iphone_rounded
                                            : Icons.mail_outline_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            otpRequested
                                                ? (isPhoneFlow
                                                    ? 'Verify your number'
                                                    : 'Verify your email')
                                                : isSignupMode
                                                ? 'Create your account'
                                                : 'Welcome back',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            otpRequested
                                                ? 'We sent a one-time code to ${controller.maskedDestination}.'
                                                : isSignupMode
                                                ? 'Signup is identifier-first. Onboarding follows.'
                                                : (isPhoneFlow
                                                    ? 'Use your phone number and continue with OTP verification.'
                                                    : 'Use your email address and continue with verification.'),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              if (!otpRequested)
                                  TextField(
                                    key: ValueKey('auth_input_${isPhoneFlow ? 'phone' : 'email'}'),
                                    onChanged: (val) =>
                                        controller.identifier.value = val,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: isPhoneFlow
                                        ? TextInputType.phone
                                        : TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      hintText: isPhoneFlow
                                          ? 'Phone number'
                                          : 'Email address',
                                      hintStyle: const TextStyle(
                                        color: Colors.white54,
                                      ),
                                      prefixIcon: Icon(
                                        isPhoneFlow ? Icons.phone : Icons.email,
                                        color: Colors.white,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black.withValues(
                                        alpha: 0.18,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                              if (otpRequested) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  onChanged: (val) =>
                                      controller.otpCode.value = val,
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Verification code',
                                    hintStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Colors.white,
                                    ),
                                    filled: true,
                                    fillColor: Colors.black.withValues(
                                      alpha: 0.18,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.resetVerificationFlow,
                                    child: Text(
                                      isPhoneFlow
                                          ? 'Use a different number'
                                          : 'Use a different email',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                                Text(
                                  otpRequested
                                      ? 'Complete verification first. License, vehicle, and registration details are collected after your account is confirmed.'
                                      : isSignupMode
                                      ? 'Creating an account only reserves your identity. Your driver profile is a separate registration step.'
                                      : (isPhoneFlow
                                          ? 'Phone authentication is passwordless, so we will text you a verification code to continue.'
                                          : 'Email authentication is passwordless, so we will email you a verification code to continue.'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF778DA9),
                                  foregroundColor: const Color(0xFF0D1B2A),
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : Text(
                                        otpRequested
                                            ? 'Verify code'
                                            : isSignupMode
                                            ? 'Create account'
                                            : 'Continue',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              if (otpRequested) ...[
                                const SizedBox(height: 12),
                                Obx(
                                  () => TextButton(
                                    onPressed: controller.isResending.value
                                        ? null
                                        : controller.resendCode,
                                    child: Text(
                                      controller.isResending.value
                                          ? 'Sending another code...'
                                          : 'Resend code',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF778DA9)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0D1B2A) : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
