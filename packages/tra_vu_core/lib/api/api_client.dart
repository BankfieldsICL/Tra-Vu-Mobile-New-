import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../services/auth_service.dart';

class ApiClient extends GetxService {
  late Dio _dio;

  ApiClient init({
    required String baseUrl,
    required String tenantId,
    required String apiKey,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final authService = Get.find<AuthService>();

          options.headers['x-tenant-id'] = tenantId;
          options.headers['x-api-key'] = apiKey;

          final token = authService.currentUserToken.value;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          debugPrint("[API] Request: ${options.method} @$baseUrl :: ${options.path} :: Tenant: ${options.headers['x-tenant-id']}, $tenantId");
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final request = e.requestOptions;
          final authService = Get.find<AuthService>();
          final shouldSkipRefresh = request.extra['skipAuthRefresh'] == true;
          final hasRetried = request.extra['authRetryAttempted'] == true;
          final isAuthEndpoint = _isAuthEndpoint(request.path);

          if (e.response?.statusCode == 401 &&
              !shouldSkipRefresh &&
              !hasRetried &&
              !isAuthEndpoint) {
            final newToken = await authService.refreshToken();

            if (newToken != null && newToken.isNotEmpty) {
              request.headers['Authorization'] = 'Bearer $newToken';
              request.extra['authRetryAttempted'] = true;

              try {
                final response = await _dio.fetch(request);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                if (retryError.response?.statusCode == 401) {
                  await authService.logout(notifyServer: false);
                }
                return handler.next(retryError);
              }
            }

            await authService.logout(notifyServer: false);
          }

          return handler.next(e);
        },
      ),
    );

    return this;
  }

  Dio get dio => _dio;

  bool _isAuthEndpoint(String path) {
    return path == '/v1/auth/refresh' ||
        path == '/v1/auth/logout' ||
        path == '/v1/auth/me';
  }
}
