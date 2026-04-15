import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/config/api_config.dart';
import 'package:tra_vu_core/tra_vu_core.dart';

enum DriverAuthMode { signIn, signUp }

enum AuthInputMethod { phone, email }

class DriverAuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final DriverApi _driverApi = Get.find<DriverApi>();
  final ApiClient _apiClient = Get.find<ApiClient>();

  final Rx<DriverAuthMode> mode = DriverAuthMode.signIn.obs;
  final Rx<AuthInputMethod> inputMethod = AuthInputMethod.phone.obs;
  final RxString identifier = ''.obs;
  final RxString otpCode = ''.obs;
  final RxString firstName = ''.obs;
  final RxString lastName = ''.obs;
  final RxString emailAddress = ''.obs;
  final RxString profilePhoneNumber = ''.obs;
  final RxString licenseNumber = ''.obs;
  final RxString vehicleMake = ''.obs;
  final RxString vehicleModel = ''.obs;
  final RxString vehiclePlate = ''.obs;
  final RxString vehicleYear = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isResending = false.obs;
  final RxBool documentsVerified = false.obs;
  final RxBool otpRequested = false.obs;
  final Rxn<UserModel> currentUserProfile = Rxn<UserModel>();
  final Rxn<DriverModel> driverProfile = Rxn<DriverModel>();

  bool get isSignupMode => mode.value == DriverAuthMode.signUp;
  bool get isPhoneFlow => inputMethod.value == AuthInputMethod.phone;

  String get normalizedIdentifier => identifier.value.trim();

  String get maskedDestination => normalizedIdentifier;

  void setMode(DriverAuthMode nextMode) {
    if (mode.value == nextMode) {
      return;
    }

    mode.value = nextMode;
    resetVerificationFlow();
  }

  void setInputMethod(AuthInputMethod nextMethod) {
    if (inputMethod.value == nextMethod) {
      return;
    }

    inputMethod.value = nextMethod;
    identifier.value = '';
    resetVerificationFlow();
  }

  void resetVerificationFlow() {
    otpRequested.value = false;
    otpCode.value = '';
    _authService.tempUid.value = null;
  }

  Future<void> submit() async {
    if (otpRequested.value) {
      await verifyOtp();
      return;
    }

    await submitIdentifier();
  }

  Future<void> submitIdentifier() async {
    final normalized = identifier.value.trim();
    if (normalized.isEmpty) {
      Get.snackbar(
        isPhoneFlow ? 'Phone required' : 'Email required',
        isPhoneFlow
            ? 'Enter a valid phone number to continue.'
            : 'Enter a valid email address to continue.',
        colorText: Colors.white,
      );
      return;
    }

    String? finalValue;

    if (isPhoneFlow) {
      finalValue = _normalizePhone(normalized);
      if (finalValue == null) {
        Get.snackbar(
          'Invalid phone',
          'Enter a valid phone number to continue.',
          colorText: Colors.white,
        );
        return;
      }
    } else {
      if (!GetUtils.isEmail(normalized)) {
        Get.snackbar(
          'Invalid email',
          'Enter a valid email address to continue.',
          colorText: Colors.white,
        );
        return;
      }
      finalValue = normalized;
    }

    isLoading.value = true;

    try {
      final response = await _apiClient.dio.post(
        isSignupMode ? ApiEndpoints.authSignup : ApiEndpoints.authSignin,
        data: {
          'method':
              (isPhoneFlow ? AuthStrategy.phone : AuthStrategy.email)
                  .name
                  .toUpperCase(),
          if (isPhoneFlow) 'phone': finalValue else 'email': finalValue,
        },
      );

      await _handleAuthResponse(
        response.data,
        normalizedValue: finalValue,
        isPhone: isPhoneFlow,
      );
    } catch (error) {
      debugPrint('[Driver Auth] Submit identifier error: $error');
      Get.snackbar(
        isSignupMode ? 'Signup failed' : 'Sign in failed',
        _readableErrorMessage(
          error,
          fallback: 'We could not continue right now. Please try again.',
        ),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    final uid = _authService.tempUid.value;
    if (uid == null || uid.isEmpty) {
      otpRequested.value = false;
      Get.snackbar(
        'Session expired',
        'Request a new verification code to keep going.',
        colorText: Colors.white,
      );
      return;
    }

    if (otpCode.value.trim().length < 4) {
      Get.snackbar('OTP required', 'Enter the code you received to continue.', colorText: Colors.white );
      return;
    }

    isLoading.value = true;
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.authVerify,
        data: {'uid': uid, 'code': otpCode.value.trim()},
      );

      await _handleAuthResponse(
        response.data,
        normalizedValue: normalizedIdentifier,
        isPhone: isPhoneFlow,
      );
    } catch (error) {
      debugPrint('[Driver Auth] Verify OTP error: $error');
      Get.snackbar(
        'Verification failed',
        _readableErrorMessage(
          error,
          fallback: 'Invalid or expired verification code.',
        ),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendCode() async {
    final uid = _authService.tempUid.value;
    if (uid == null || uid.isEmpty) {
      otpRequested.value = false;
      Get.snackbar('Session expired', 'Start again to request a new code.', colorText: Colors.white);
      return;
    }

    isResending.value = true;
    try {
      await _apiClient.dio.post(ApiEndpoints.authResend, data: {'uid': uid});
      Get.snackbar('Code sent', 'A new verification code is on the way.', colorText: Colors.white);
    } catch (error) {
      Get.snackbar(
        'Unable to resend',
        _readableErrorMessage(error, fallback: 'Please try again in a moment.'),
        colorText: Colors.white,
      );
    } finally {
      isResending.value = false;
    }
  }

  Future<void> submitDocuments() async {
    final userId = await _resolveAppUserId();
    if (userId == null || userId.isEmpty) {
      Get.snackbar('Session missing', 'Sign in again to finish onboarding.', colorText: Colors.white);
      Get.offAllNamed('/login');
      return;
    }

    if (!_hasRequiredDocuments) {
      Get.snackbar(
        'Complete onboarding',
        'Add your license and vehicle details before continuing.',
        // colorText: Colors.white
      );
      return;
    }

    isLoading.value = true;

    try {
      final existingDriver =
          driverProfile.value ?? await _findDriverProfile(userId);
      final driver =
          existingDriver ??
          await _driverApi.createDriverProfile(
            userId: userId,
            licenseNumber: licenseNumber.value.trim(),
          );

      driverProfile.value = driver;

      await _driverApi.createVehicle(
        driverId: driver.id,
        make: vehicleMake.value.trim(),
        model: vehicleModel.value.trim(),
        year: int.tryParse(vehicleYear.value.trim()) ?? DateTime.now().year,
        licensePlate: vehiclePlate.value.trim().toUpperCase(),
      );

      documentsVerified.value = true;
      Get.offAllNamed('/dispatch');
    } catch (error) {
      _logApiError('Onboarding issue', error);
      Get.snackbar(
        'Onboarding issue',
        _readableErrorMessage(
          error,
          fallback:
              'We could not save your driver details right now. Please try again.',
        ),
        // colorText: Colors.white
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> continueAfterRestoredSession() async {
    await _routeAfterAuthentication();
  }

  void backToLogin() {
    Get.offAllNamed('/login');
  }

  void backToProfileDetails() {
    Get.offNamed('/auth/profile-details');
  }

  Future<void> _routeAfterAuthentication() async {
    _hydrateContactFieldsFromAuthSession();

    final userId = await _resolveAppUserId();
    if (userId == null || userId.isEmpty) {
      Get.snackbar('Missing profile', 'We could not load your driver account.', colorText: Colors.white);
      return;
    }

    // Ensure WebSocket is initialized on session restoration
    final token = _authService.currentUserToken.value;
    if (token != null && token.isNotEmpty) {
      final socketService = Get.find<TrackingSocketService>();
      await socketService.init(ApiConfig.baseSocketUrl, token, ApiConfig.tenantId);
    }

    final profile = await _loadCurrentUserProfile();
    final driver = await _findDriverProfile(userId);
    driverProfile.value = driver;
    documentsVerified.value = driver != null;

    if (_needsProfileCompletion(profile)) {
      Get.offNamed('/auth/profile-details');
      return;
    }

    if (driver == null) {
      Get.offNamed('/auth/documents');
      return;
    }

    Get.offAllNamed('/dispatch');
  }

  Future<DriverModel?> _findDriverProfile(String userId) async {
    try {
      return await _driverApi.getMyDriverProfile();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveAppUserId() async {
    final sessionUserId = _authService.currentUserId.value;
    final accessToken = _authService.currentUserToken.value;

    try {
      final profile = await _driverApi.getProfile();
      await _persistCanonicalUser(profile.id, accessToken);
      return profile.id;
    } catch (_) {
      return sessionUserId;
    }
  }

  Future<UserModel?> _loadCurrentUserProfile() async {
    try {
      final profile = await _driverApi.getProfile();
      currentUserProfile.value = profile;
      _hydrateProfileFields(profile);
      await _persistCanonicalUser(
        profile.id,
        _authService.currentUserToken.value,
      );
      return profile;
    } catch (_) {
      _hydrateContactFieldsFromAuthSession();
      return currentUserProfile.value;
    }
  }

  Future<void> submitProfileDetails() async {
    if (!_hasRequiredProfileDetails) {
      Get.snackbar(
        'Complete profile',
        'Add your first name, last name, and a phone number or email to continue.',
        colorText: Colors.white
      );
      return;
    }

    isLoading.value = true;

    try {
      final profile = await _driverApi.updateMyProfile(
        firstName: firstName.value.trim(),
        lastName: lastName.value.trim(),
        email: _normalizedEmail,
        phoneNumber: _normalizedProfilePhone,
      );
      currentUserProfile.value = profile;
      await _persistCanonicalUser(
        profile.id,
        _authService.currentUserToken.value,
      );

      final driver =
          driverProfile.value ?? await _findDriverProfile(profile.id);
      driverProfile.value = driver;
      if (driver == null) {
        Get.offNamed('/auth/documents');
      } else {
        Get.offAllNamed('/dispatch');
      }
    } catch (error) {
      _logApiError('Profile completion issue', error);
      Get.snackbar(
        'Profile update failed',
        _readableErrorMessage(
          error,
          fallback:
              'We could not save your profile details right now. Please try again.',
        ),
        // colorText: Colors.white
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _persistCanonicalUser(String userId, String? accessToken) async {
    if (userId.isEmpty ||
        accessToken == null ||
        accessToken.isEmpty ||
        userId == _authService.currentUserId.value) {
      return;
    }

    await _authService.persistSession(
      accessToken: accessToken,
      refreshToken: _authService.currentRefreshToken.value,
      userId: userId,
    );
  }

  Future<void> _handleAuthResponse(
    dynamic rawData, {
    required String normalizedValue,
    required bool isPhone,
  }) async {
    if (rawData is! Map<String, dynamic>) {
      Get.snackbar(
        'Unexpected response',
        'The server returned an unknown response.',
        colorText: Colors.white
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
        payload['userId']?.toString() ??
        auth?['uid']?.toString() ??
        auth?['id']?.toString();
    final responseEmail =
        user?['email']?.toString() ??
        auth?['email']?.toString() ??
        payload['email']?.toString();
    final responsePhone =
        user?['phoneNumber']?.toString() ??
        user?['phone']?.toString() ??
        auth?['phoneNumber']?.toString() ??
        auth?['phone']?.toString() ??
        payload['phoneNumber']?.toString() ??
        payload['phone']?.toString();

    identifier.value = normalizedValue;
    if (responseEmail != null && responseEmail.trim().isNotEmpty) {
      emailAddress.value = responseEmail.trim();
    } else if (!isPhone) {
      emailAddress.value = normalizedValue;
    }

    if (responsePhone != null && responsePhone.trim().isNotEmpty) {
      profilePhoneNumber.value = responsePhone.trim();
    } else if (isPhone) {
      profilePhoneNumber.value = normalizedValue;
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      await _authService.persistSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId ?? uid,
      );

      // Initialize WebSocket for real-time job offers
      final socketService = Get.find<TrackingSocketService>();
      await socketService.init(ApiConfig.baseSocketUrl, accessToken, ApiConfig.tenantId);

      try {
        await _authService.loadCurrentAuthProfile();
      } catch (_) {
        // Prefill can still fall back to the auth response or user profile.
      }
      otpCode.value = '';
      otpRequested.value = false;

      await _routeAfterAuthentication();
      return;
    }

    if ((verificationRequired || uid != null) &&
        uid != null &&
        uid.isNotEmpty) {
      _authService.tempUid.value = uid;
      otpRequested.value = true;
      otpCode.value = '';
      Get.snackbar(
        isSignupMode ? 'Account created' : 'Code sent',
        'Enter the verification code sent to $normalizedValue.',
        colorText: Colors.white
      );
      return;
    }

    Get.snackbar(
      'Authentication incomplete',
      'We did not receive a session or verification challenge from the server.',
      colorText: Colors.white
    );
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> rawData) {
    final data = rawData['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return rawData;
  }

  bool get _hasRequiredProfileDetails =>
      firstName.value.trim().isNotEmpty &&
      lastName.value.trim().isNotEmpty &&
      (_normalizedProfilePhone != null || _normalizedEmail != null);

  bool get _hasRequiredDocuments =>
      licenseNumber.value.trim().isNotEmpty &&
      vehicleMake.value.trim().isNotEmpty &&
      vehicleModel.value.trim().isNotEmpty &&
      vehiclePlate.value.trim().isNotEmpty &&
      vehicleYear.value.trim().isNotEmpty;

  bool _needsProfileCompletion(UserModel? profile) {
    if (profile == null) {
      return true;
    }

    final hasName =
        profile.firstName.trim().isNotEmpty &&
        profile.lastName.trim().isNotEmpty;
    final hasContact =
        (profile.phoneNumber?.trim().isNotEmpty ?? false) ||
        (profile.email?.trim().isNotEmpty ?? false) ||
        _normalizedProfilePhone != null ||
        emailAddress.value.trim().isNotEmpty;

    return !hasName || !hasContact;
  }

  void _hydrateProfileFields(UserModel profile) {
    if (profile.firstName.trim().isNotEmpty) {
      firstName.value = profile.firstName;
    }
    if (profile.lastName.trim().isNotEmpty) {
      lastName.value = profile.lastName;
    }
    if (profile.email?.trim().isNotEmpty ?? false) {
      emailAddress.value = profile.email!.trim();
    }

    if (profile.phoneNumber?.trim().isNotEmpty ?? false) {
      profilePhoneNumber.value = profile.phoneNumber!.trim();
    } else if (profilePhoneNumber.value.trim().isEmpty) {
      final authPhone = _normalizePhone(identifier.value);
      if (authPhone != null) {
        profilePhoneNumber.value = authPhone;
      }
    }
  }

  void _hydrateContactFieldsFromAuthSession() {
    final authEmail = _authService.currentAuthEmail;
    if (authEmail != null && authEmail.isNotEmpty) {
      emailAddress.value = authEmail;
    }

    final authPhone = _authService.currentAuthPhone ?? _normalizePhone(identifier.value);
    if (authPhone != null && authPhone.isNotEmpty) {
      profilePhoneNumber.value = authPhone;
    }
  }

  String? get _normalizedProfilePhone {
    final rawPhone = profilePhoneNumber.value.trim();
    if (rawPhone.isEmpty) {
      return null;
    }

    return _normalizePhone(rawPhone);
  }

  String? get _normalizedEmail {
    final rawEmail = emailAddress.value.trim();
    if (rawEmail.isEmpty) {
      return null;
    }

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(rawEmail)) {
      return null;
    }

    return rawEmail;
  }

  String? _normalizePhone(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (digitsOnly.length < 10) {
      return null;
    }

    if (digitsOnly.startsWith('+')) {
      return digitsOnly;
    }

    return '+$digitsOnly';
  }

  String _readableErrorMessage(Object error, {required String fallback}) {
    final serverMessage = _extractServerMessage(error);
    if (serverMessage != null) {
      return serverMessage;
    }

    final message = error.toString().trim();
    if (_looksSafeForUsers(message)) {
      return message.replaceFirst('Exception: ', '').trim();
    }

    return fallback;
  }

  void _logApiError(String label, Object error) {
    debugPrint('[Driver Auth] $label: $error');

    try {
      final dynamic dynamicError = error;
      final response = dynamicError.response;
      if (response != null) {
        debugPrint('[Driver Auth] $label status: ${response.statusCode}');
        debugPrint('[Driver Auth] $label data: ${response.data}');
      }
    } catch (_) {
      // Ignore errors without Dio-style response objects.
    }
  }

  String? _extractServerMessage(Object error) {
    dynamic source = error;

    try {
      final response = source.response;
      if (response != null) {
        source = response.data;
      }
    } catch (_) {
      // Ignore missing dynamic properties and keep falling back.
    }

    return _messageFromPayload(source);
  }

  String? _messageFromPayload(dynamic payload) {
    if (payload == null) {
      return null;
    }

    if (payload is String) {
      final trimmed = payload.trim();
      return _looksSafeForUsers(trimmed) ? trimmed : null;
    }

    if (payload is Map) {
      final directMessage = payload['message'];
      if (directMessage is String && _looksSafeForUsers(directMessage.trim())) {
        return directMessage.trim();
      }

      final errorMessage = payload['error'];
      if (errorMessage is String && _looksSafeForUsers(errorMessage.trim())) {
        return errorMessage.trim();
      }

      final data = payload['data'];
      if (data != null) {
        final nestedMessage = _messageFromPayload(data);
        if (nestedMessage != null) {
          return nestedMessage;
        }
      }
    }

    if (payload is Iterable) {
      for (final item in payload) {
        final nestedMessage = _messageFromPayload(item);
        if (nestedMessage != null) {
          return nestedMessage;
        }
      }
    }

    return null;
  }

  bool _looksSafeForUsers(String message) {
    if (message.isEmpty ||
        message == 'Exception' ||
        message == 'null' ||
        message.length > 180) {
      return false;
    }

    final technicalPatterns = <RegExp>[
      RegExp(r'dioexception', caseSensitive: false),
      RegExp(r'socketexception', caseSensitive: false),
      RegExp(r'stack trace', caseSensitive: false),
      RegExp(r'status code of \d{3}', caseSensitive: false),
      RegExp(r'xmlhttprequest', caseSensitive: false),
      RegExp(r'cannot read propert', caseSensitive: false),
      RegExp('type [\\\'"]', caseSensitive: false),
      RegExp(r'\b(?:http|https)://', caseSensitive: false),
    ];

    for (final pattern in technicalPatterns) {
      if (pattern.hasMatch(message)) {
        return false;
      }
    }

    return true;
  }
}
