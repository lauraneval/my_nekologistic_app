import 'dart:io';

import 'package:dio/dio.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../config/app_env.dart';
import '../../features/auth/data/auth_service.dart';

class ApiClient {
  ApiClient({required AuthService authService})
    : _authService = authService,
      _dio = Dio(
        BaseOptions(
          baseUrl: _normalizeBaseUrl(AppEnv.apiBaseUrl),
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          contentType: 'application/json',
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getBearerToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final AuthService _authService;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    _validateBaseUrl();
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(String path, {Object? data}) {
    _validateBaseUrl();
    return _dio.post(path, data: data);
  }

  Future<Response<dynamic>> put(String path, {Object? data}) {
    _validateBaseUrl();
    return _dio.put(path, data: data);
  }

  Future<Response<dynamic>> patch(String path, {Object? data}) {
    _validateBaseUrl();
    return _dio.patch(path, data: data);
  }

  void _validateBaseUrl() {
    if (AppEnv.apiBaseUrl.isEmpty) {
      throw StateError('API_BASE_URL belum dikonfigurasi.');
    }
    if (!AppBootstrap.isSupabaseInitialized) {
      return;
    }
  }

  static String _normalizeBaseUrl(String baseUrl) {
    if (baseUrl.isEmpty) {
      return baseUrl;
    }

    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasAuthority || !Platform.isAndroid) {
      return baseUrl;
    }

    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return uri.replace(host: '10.0.2.2').toString();
    }

    return baseUrl;
  }
}
