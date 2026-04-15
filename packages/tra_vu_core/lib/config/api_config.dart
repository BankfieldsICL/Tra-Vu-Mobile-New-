import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _debugBaseUrl = 'http://192.168.1.8:4050/api';
  static const String _releaseBaseUrl = 'https://api.tra-vu.com/api';

  static const String _debugHostUrl = 'http://192.168.1.8:4050';
  static const String _releaseHostUrl = 'https://api.tra-vu.com';

  static const String version = '/v1';

  static const String baseUrl = kDebugMode ? _debugBaseUrl : _releaseBaseUrl;
  static const String baseSocketUrl = "${kDebugMode ? _debugHostUrl : _releaseHostUrl}/tracking";
  static const String tenantId = 'f5f93beb-0b1d-4812-b3a3-703cd0a76bd5';
  static const String apiKey = 'tv_730ba20116d83dd5348455c8697162dae6ede1ad54c0e691';
  
  // Refresh token endpoint
  static const String refreshTokenEndpoint = '$version/auth/refresh';

}
