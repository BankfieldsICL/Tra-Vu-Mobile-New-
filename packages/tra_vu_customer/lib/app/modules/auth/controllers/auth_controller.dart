import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tra_vu_core/api/api_client.dart';
import 'package:tra_vu_core/api/api_endpoints.dart';
import 'package:tra_vu_core/config/api_config.dart';
import 'package:tra_vu_core/models/shared_models.dart';
import 'package:tra_vu_core/services/auth_service.dart';
import 'package:tra_vu_core/sockets/tracking_socket_service.dart';

enum AuthFlowMode { signIn, signUp }

enum AuthInputMethod { phone, email }

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ApiClient _apiClient = Get.find<ApiClient>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final Rx<AuthFlowMode> mode = AuthFlowMode.signIn.obs;
  final Rx<AuthInputMethod> inputMethod = AuthInputMethod.phone.obs;

  final RxString identifier = ''.obs;
  final RxString password = ''.obs;
  final RxString otp = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isResending = false.obs;

  String get maskedDestination => identifier.value.trim();
  bool get isPhoneFlow => inputMethod.value == AuthInputMethod.phone;
  bool get isSignUpFlow => mode.value == AuthFlowMode.signUp;

  void setMode(AuthFlowMode nextMode) {
    if (mode.value == nextMode) return;
    mode.value = nextMode;
  }

  void setInputMethod(AuthInputMethod nextMethod) {
    if (inputMethod.value == nextMethod) return;
    inputMethod.value = nextMethod;
    identifier.value = '';
    password.value = '';
  }

  Future<void> submitCredentials() async {
    final normalizedIdentifier = identifier.value.trim();
    final normalizedPassword = password.value.trim();
    final shouldSendPassword = !isPhoneFlow && normalizedPassword.isNotEmpty;

    if (normalizedIdentifier.isEmpty) {
      Get.snackbar(
        'Missing Details',
        'Enter your phone number or email address.',
      );
      return;
    }

    if (isPhoneFlow && normalizedIdentifier.length < 10) {
      Get.snackbar('Invalid Input', 'Enter a valid phone number.');
      return;
    }

    if (!isPhoneFlow && !GetUtils.isEmail(normalizedIdentifier)) {
      Get.snackbar('Invalid Input', 'Enter a valid email address.');
      return;
    }

    if (shouldSendPassword && normalizedPassword.length < 6) {
      Get.snackbar(
        'Invalid Password',
        'Password must be at least 6 characters.',
      );
      return;
    }

    isLoading.value = true;

    try {
      final response = await _apiClient.dio.post(
        mode.value == AuthFlowMode.signIn
            ? ApiEndpoints.authSignin
            : ApiEndpoints.authSignup,
        data: {
          'method': _authStrategy.name.toUpperCase(),
          if (isPhoneFlow) 'phone': normalizedIdentifier,
          if (!isPhoneFlow) 'email': normalizedIdentifier,
          if (shouldSendPassword) 'password': normalizedPassword,
        },
      );

      await _handleAuthResponse(response.data);
    } catch (error) {
      debugPrint('[Auth] Submit credentials error: $error');
      Get.snackbar(
        'Authentication Failed',
        _readableErrorMessage(
          error,
          fallback: 'We could not complete your request. Please try again.',
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitOTP() async {
    if (otp.value.trim().length != 6) {
      Get.snackbar('Invalid Code', 'Enter the 6-digit verification code.');
      return;
    }

    final uid = _authService.tempUid.value;
    if (uid == null || uid.isEmpty) {
      Get.snackbar(
        'Session Error',
        'Verification session expired. Please restart the sign-in flow.',
      );
      Get.offAllNamed('/login');
      return;
    }

    isLoading.value = true;

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.authVerify,
        data: {'uid': uid, 'code': otp.value.trim()},
      );

      await _handleAuthResponse(response.data);
    } catch (error) {
      debugPrint('[Auth] Verify OTP error: $error');
      Get.snackbar(
        'Verification Failed',
        _readableErrorMessage(
          error,
          fallback: 'Invalid or expired verification code.',
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendVerificationCode() async {
    final uid = _authService.tempUid.value;
    if (uid == null || uid.isEmpty) {
      Get.snackbar('Session Error', 'Start again to request a new code.');
      Get.offAllNamed('/login');
      return;
    }

    isResending.value = true;
    try {
      await _apiClient.dio.post(ApiEndpoints.authResend, data: {'uid': uid});
      Get.snackbar('Code Sent', 'A new verification code is on the way.');
    } catch (error) {
      debugPrint('[Auth] Resend verification error: $error');
      Get.snackbar(
        'Unable to Resend',
        _readableErrorMessage(error, fallback: 'Please try again in a moment.'),
      );
    } finally {
      isResending.value = false;
    }
  }

  Future<void> _handleAuthResponse(dynamic rawData) async {
    if (rawData is! Map<String, dynamic>) {
      Get.snackbar(
        'Unexpected Response',
        'The server returned an unknown response.',
      );
      return;
    }

    final payload = _unwrapPayload(rawData);
    final auth = payload['auth'] as Map<String, dynamic>?;
    final tokens = payload['tokens'] as Map<String, dynamic>?;
    final user = payload['user'] as Map<String, dynamic>?;
    final verificationRequired = payload['verificationRequired'] == true;

    final uid =
        payload['uid']?.toString() ??
        auth?['uid']?.toString() ??
        auth?['id']?.toString();
    final accessToken =
        payload['accessToken']?.toString() ??
        tokens?['accessToken']?.toString();
    final refreshToken =
        payload['refreshToken']?.toString() ??
        tokens?['refreshToken']?.toString();
    final userId =
        user?['id']?.toString() ??
        auth?['uid']?.toString() ??
        auth?['id']?.toString();

    if (accessToken != null && accessToken.isNotEmpty) {
      await _persistSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
      );
      otp.value = '';
      _authService.tempUid.value = null;
      Get.offAllNamed('/home');
      return;
    }

    if (verificationRequired && uid != null && uid.isNotEmpty) {
      _authService.tempUid.value = uid;
      otp.value = '';
      Get.toNamed('/auth/otp');
      return;
    }

    if (uid != null && uid.isNotEmpty && accessToken == null) {
      _authService.tempUid.value = uid;
      otp.value = '';
      Get.toNamed('/auth/otp');
      return;
    }

    Get.snackbar(
      'Authentication Incomplete',
      'We did not receive a session or verification challenge from the server.',
    );
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> rawData) {
    final data = rawData['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return rawData;
  }

  Future<void> _persistSession({
    required String accessToken,
    String? refreshToken,
    String? userId,
  }) async {
    await _storage.write(key: 'jwt', value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    } else {
      await _storage.delete(key: 'refresh_token');
    }
    if (userId != null && userId.isNotEmpty) {
      await _storage.write(key: 'user_id', value: userId);
    } else {
      await _storage.delete(key: 'user_id');
    }

    _authService.isAuthenticated.value = true;
    _authService.currentUserToken.value = accessToken;
    _authService.currentRefreshToken.value = refreshToken;
    _authService.currentUserId.value = userId;

    final socketService = Get.find<TrackingSocketService>();
    await socketService.init(
      ApiConfig.baseSocketUrl,
      accessToken,
      ApiConfig.tenantId,
    );
  }

  AuthStrategy get _authStrategy {
    switch (inputMethod.value) {
      case AuthInputMethod.phone:
        return AuthStrategy.phone;
      case AuthInputMethod.email:
        return AuthStrategy.email;
    }
  }

  String _readableErrorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }

        if (message is List) {
          final combined = message
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .join('\n');
          if (combined.isNotEmpty) {
            return combined;
          }
        }
      }

      final dioMessage = error.message?.trim();
      if (dioMessage != null && dioMessage.isNotEmpty) {
        return dioMessage;
      }
    }

    return fallback;
  }
}
