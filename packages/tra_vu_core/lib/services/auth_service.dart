import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tra_vu_core/api/api_client.dart';
import 'package:tra_vu_core/api/api_endpoints.dart';
import 'package:tra_vu_core/config/api_config.dart';
import 'package:tra_vu_core/models/shared_models.dart';
import 'package:tra_vu_core/sockets/tracking_socket_service.dart';
import 'package:provider/provider.dart';
import 'package:vynemit_flutter/vynemit_flutter.dart';

class AuthService extends GetxService {
  final _storage = const FlutterSecureStorage();
  Future<bool>? _restoreSessionFuture;
  Future<String?>? _refreshTokenFuture;
  Future<void>? _logoutFuture;

  final RxBool isAuthenticated = false.obs;
  final RxnString currentUserToken = RxnString();
  final RxnString currentRefreshToken = RxnString();
  final RxnString currentUserId = RxnString();
  final Rxn<Map<String, dynamic>> currentAuthProfile = Rxn<Map<String, dynamic>>();

  // Temporal UID from the first step of auth
  final RxnString tempUid = RxnString();

  @override
  void onInit() {
    super.onInit();
    restoreAndValidateSession();
  }

  Future<bool> restoreAndValidateSession({bool force = false}) {
    if (force || _restoreSessionFuture == null) {
      _restoreSessionFuture = _restoreAndValidateSession();
    }
    return _restoreSessionFuture!;
  }

  Future<bool> _restoreAndValidateSession() async {
    final token = await _storage.read(key: 'jwt');
    final refreshToken = await _storage.read(key: 'refresh_token');
    final userId = await _storage.read(key: 'user_id');

    if (token == null || token.isEmpty) {
      _clearSessionState();
      return false;
    }

    currentUserToken.value = token;
    currentRefreshToken.value = refreshToken;
    currentUserId.value = userId;

    final isValid = await _validateSessionWithServer();
    if (!isValid) {
      await _clearStoredSession();
      _clearSessionState();
      return false;
    }

    _configureSession(
      currentUserToken.value!,
      currentRefreshToken.value,
      userId,
    );
    return true;
  }

  Future<bool> _validateSessionWithServer() async {
    try {
      await loadCurrentAuthProfile(logLabel: '[Auth] auth/me response');
      return true;
    } catch (_) {
      final refreshedToken = await refreshToken();
      if (refreshedToken == null || refreshedToken.isEmpty) {
        return false;
      }

      try {
        await loadCurrentAuthProfile(
          logLabel: '[Auth] auth/me response after refresh',
        );
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<Map<String, dynamic>?> loadCurrentAuthProfile({
    String logLabel = '[Auth] auth/me response',
  }) async {
    final apiClient = Get.find<ApiClient>();
    final response = await apiClient.dio.get(
      ApiEndpoints.authMe,
      options: Options(extra: {'skipAuthRefresh': true}),
    );
    print('$logLabel: ${response.data}');
    return _cacheAuthProfile(response.data);
  }

  String? get currentAuthEmail =>
      _extractIdentityValue(currentAuthProfile.value, const ['email']);

  String? get currentAuthPhone => _extractIdentityValue(
        currentAuthProfile.value,
        const ['phoneNumber', 'phone'],
      );

  void _configureSession(String token, String? refreshToken, String? userId) {
    isAuthenticated.value = true;
    currentUserId.value = userId;
    currentUserToken.value = token;
    currentRefreshToken.value = refreshToken;

    print("Session Configured for user $userId");

    // Connect Socket with verified token
    final socketService = Get.find<TrackingSocketService>();
    socketService.init(ApiConfig.baseSocketUrl, token, ApiConfig.tenantId);

    // Initialize Vynemit client mapping
    _initializeVynemit(userId);
  }

  Future<void> persistSession({
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

    _configureSession(accessToken, refreshToken, userId);
    tempUid.value = null;
  }

  /// First step of OTP flow: Request a code
  Future<String?> requestPhoneOtp(String phone) async {
    final apiClient = Get.find<ApiClient>();
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.authSignin,
        data: {'method': AuthStrategy.phone.name.toUpperCase(), 'phone': phone},
      );

      // The backend returns a UID for the verification step
      final uid = response.data['uid'] as String?;
      tempUid.value = uid;
      return uid;
    } catch (e) {
      print("[Auth] Request OTP Error: $e");
      return null;
    }
  }

  /// Second step of OTP flow: Verify the code
  Future<bool> verifyOtp(String uid, String code) async {
    final apiClient = Get.find<ApiClient>();
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.authVerify,
        data: {'uid': uid, 'code': code},
      );

      final token = response.data['accessToken'] as String;
      final refreshToken = response.data['refreshToken'] as String;
      final userId = response.data['user']?['id'] as String?;

      await _storage.write(key: 'jwt', value: token);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      if (userId != null) {
        await _storage.write(key: 'user_id', value: userId);
      }

      _configureSession(token, refreshToken, userId);
      tempUid.value = null;
      return true;
    } catch (e) {
      print("[Auth] Verify OTP Error: $e");
      return false;
    }
  }

  Future<void> logout({bool notifyServer = true}) {
    _logoutFuture ??= _logoutInternal(notifyServer: notifyServer);
    return _logoutFuture!;
  }

  Future<void> _logoutInternal({bool notifyServer = true}) async {
    final apiClient = Get.find<ApiClient>();
    final refreshToken = currentRefreshToken.value;

    try {
      if (notifyServer && refreshToken != null) {
        await apiClient.dio.post(
          ApiEndpoints.authLogout,
          data: {'refreshToken': refreshToken},
          options: Options(extra: {'skipAuthRefresh': true}),
        );
      }
    } catch (e) {
      print("[Auth] Backend Logout Error: $e");
    } finally {
      await _clearStoredSession();
      _clearSessionState();

      // Disconnect sockets
      final socketService = Get.find<TrackingSocketService>();
      await socketService.disconnect();

      Get.offAllNamed('/login');
      _logoutFuture = null;
    }
  }

  Future<String?> refreshToken() async {
    _refreshTokenFuture ??= _refreshTokenInternal();
    final refreshed = await _refreshTokenFuture;
    _refreshTokenFuture = null;
    return refreshed;
  }

  Future<String?> _refreshTokenInternal() async {
    final apiClient = Get.find<ApiClient>();
    final storedRefreshToken = currentRefreshToken.value;

    if (storedRefreshToken == null) return null;

    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': storedRefreshToken},
        options: Options(extra: {'skipAuthRefresh': true}),
      );

      final tokens = response.data['data']['tokens'];

      final newToken = tokens['accessToken'] as String;
      final newRefreshToken = tokens['refreshToken'] as String;

      // Only update state — do NOT re-init the socket here.
      // The socket will be initialized once by _configureSession after full validation.
      currentUserToken.value = newToken;
      currentRefreshToken.value = newRefreshToken;

      await _storage.write(key: 'jwt', value: newToken);
      await _storage.write(key: 'refresh_token', value: newRefreshToken);

      // If socket is already connected, push the new token instead of reconnecting
      final socketService = Get.find<TrackingSocketService>();
      if (socketService.isConnected.value) {
        socketService.pushNewToken(newToken);
      }

      // Notify Vynemit of the refreshed token
      final context = Get.context;
      if (context != null) {
        try {
          // Pass currentUserId.value to ensure we aren't using a stale userId if it changed
          Provider.of<VynemitProvider>(context, listen: false).updateConfig(
            userId: currentUserId.value,
          );
        } catch (e) {
          debugPrint("Error notifying Vynemit of token refresh: $e");
        }
      }

      return newToken;
    } catch (e) {
      print("[Auth] Refresh Token Error: $e");
      return null;
    }
  }

  Future<void> _clearStoredSession() async {
    await _storage.delete(key: 'jwt');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
  }

  void _clearSessionState() {
    isAuthenticated.value = false;
    currentUserId.value = null;
    currentUserToken.value = null;
    currentRefreshToken.value = null;
    currentAuthProfile.value = null;
    _restoreSessionFuture = null;
    _refreshTokenFuture = null;
  }

  Map<String, dynamic>? _cacheAuthProfile(dynamic rawData) {
    if (rawData is! Map) {
      return null;
    }

    final normalized = _normalizeAuthPayload(rawData);
    currentAuthProfile.value = normalized;
    return normalized;
  }

  Map<String, dynamic> _normalizeAuthPayload(Map rawData) {
    final normalized = Map<String, dynamic>.from(rawData);
    final data = normalized['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return normalized;
  }

  String? _extractIdentityValue(
    dynamic payload,
    List<String> candidateKeys,
  ) {
    if (payload == null) {
      return null;
    }

    if (payload is Map) {
      final directIdentityValue = _extractFromIdentityMap(payload, candidateKeys);
      if (directIdentityValue != null) {
        return directIdentityValue;
      }

      for (final key in candidateKeys) {
        final value = payload[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      for (final value in payload.values) {
        final nested = _extractIdentityValue(value, candidateKeys);
        if (nested != null) {
          return nested;
        }
      }
    }

    if (payload is Iterable) {
      for (final item in payload) {
        final nested = _extractIdentityValue(item, candidateKeys);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
  }

  String? _extractFromIdentityMap(
    Map payload,
    List<String> candidateKeys,
  ) {
    final typeValue = payload['type']?.toString().toLowerCase();
    final methodValue = payload['method']?.toString().toLowerCase();
    final providerValue = payload['provider']?.toString().toLowerCase();
    final channel = typeValue ?? methodValue ?? providerValue;

    String? mappedCandidate;
    for (final key in candidateKeys) {
      if (channel == key.toLowerCase()) {
        mappedCandidate = key;
        break;
      }
    }

    if (mappedCandidate == null) {
      return null;
    }

    final valueCandidates = [
      payload['value'],
      payload['identifier'],
      payload['address'],
      payload[mappedCandidate],
    ];

    for (final candidate in valueCandidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return null;
  }

  void _initializeVynemit(String? userId) {
    if (userId == null) return;
    print("Initializing Vynemit SDK for user $userId");
    try {
      // Find the VynemitProvider from the context and update its user ID
      // Note: Since AuthService is a GetxService, we use the root context if available
      // or rely on the fact that VynemitProvider uses the config callback.
      // We can also explicitly trigger a re-sync if the SDK supports it.
      final context = Get.context;
      if (context != null) {
        Provider.of<VynemitProvider>(context, listen: false).updateConfig(
          userId: userId,
        );
      }
    } catch (e) {
      debugPrint("Error syncing Vynemit: $e");
    }
  }
}
