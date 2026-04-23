import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient replacing image
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1E3A8A),
                  Color(0xFF1D4ED8),
                  Color(0xFF3B82F6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Tra-Vu",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Your on-demand service hub.",
                            style: TextStyle(fontSize: 16, color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Flexible(
                            fit: FlexFit.loose,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Obx(() {
                                    final isPhoneFlow = controller.isPhoneFlow;
                                    final isSignUpFlow = controller.isSignUpFlow;

                                    return SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _ModeChip(
                                                  label: 'Sign in',
                                                  isSelected: !isSignUpFlow,
                                                  onTap: () =>
                                                      controller.setMode(
                                                        AuthFlowMode.signIn,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _ModeChip(
                                                  label: 'Create account',
                                                  isSelected: isSignUpFlow,
                                                  onTap: () =>
                                                      controller.setMode(
                                                        AuthFlowMode.signUp,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _MethodChip(
                                                  label: 'Phone',
                                                  icon: Icons.phone_rounded,
                                                  isSelected: isPhoneFlow,
                                                  onTap: () => controller
                                                      .setInputMethod(
                                                        AuthInputMethod.phone,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _MethodChip(
                                                  label: 'Email',
                                                  icon: Icons
                                                      .alternate_email_rounded,
                                                  isSelected: !isPhoneFlow,
                                                  onTap: () => controller
                                                      .setInputMethod(
                                                        AuthInputMethod.email,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          TextField(
                                            onChanged: (val) =>
                                                controller.identifier.value =
                                                    val,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            keyboardType: isPhoneFlow
                                                ? TextInputType.phone
                                                : TextInputType.emailAddress,
                                            decoration: InputDecoration(
                                              hintText: isPhoneFlow
                                                  ? 'Phone Number'
                                                  : 'Email Address',
                                              hintStyle: const TextStyle(
                                                color: Colors.white54,
                                              ),
                                              prefixIcon: Icon(
                                                isPhoneFlow
                                                    ? Icons.phone
                                                    : Icons.email_outlined,
                                                color: Colors.white,
                                              ),
                                              filled: true,
                                              fillColor: Colors.black
                                                  .withValues(alpha: 0.2),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                          if (!isPhoneFlow) ...[
                                            const SizedBox(height: 16),
                                            TextField(
                                              onChanged: (val) =>
                                                  controller.password.value =
                                                      val,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              obscureText: true,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Password (optional)',
                                                hintStyle: const TextStyle(
                                                  color: Colors.white54,
                                                ),
                                                prefixIcon: const Icon(
                                                  Icons.lock_outline_rounded,
                                                  color: Colors.white,
                                                ),
                                                filled: true,
                                                fillColor: Colors.black
                                                    .withValues(alpha: 0.2),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          Text(
                                            isPhoneFlow
                                                ? 'Phone authentication is passwordless. We will send a one-time verification code to continue.'
                                                : isSignUpFlow
                                                ? 'We will create your account and ask you to verify it if needed.'
                                                : 'Sign in with your preferred contact method and continue with verification when prompted.',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          ElevatedButton(
                                            onPressed:
                                                controller.isLoading.value
                                                ? null
                                                : controller
                                                      .submitCredentials,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black,
                                              minimumSize: const Size(
                                                double.infinity,
                                                54,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child:
                                                controller.isLoading.value
                                                ? const SizedBox(
                                                    height: 22,
                                                    width: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.4,
                                                        ),
                                                  )
                                                : Text(
                                                    isSignUpFlow
                                                        ? 'Create account'
                                                        : 'Continue',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: isSelected ? 0.0 : 0.14),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isSelected ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: isSelected ? 0.28 : 0.14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
