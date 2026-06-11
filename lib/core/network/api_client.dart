import 'dart:io';

import 'package:dio/dio.dart';

import '../config/app_env.dart';
import '../../features/auth/data/auth_service.dart';

class ApiClient {
  ApiClient({required AuthService authService})
      : _authService = authService,
        _dio = Dio(BaseOptions(
          baseUrl: _resolveBaseUrl(),
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          contentType: 'application/json',
        )) {
    _setupInterceptors();
  }

  final Dio _dio;
  final AuthService _authService;

  // ── Public HTTP methods ────────────────────────────────────────────────────

  Future<Response<dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(String path, {Object? data}) =>
      _dio.post(path, data: data);

  Future<Response<dynamic>> put(String path, {Object? data}) =>
      _dio.put(path, data: data);

  Future<Response<dynamic>> patch(String path, {Object? data}) =>
      _dio.patch(path, data: data);

  // ── Interceptors ───────────────────────────────────────────────────────────

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getBearerToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Attempt one silent token refresh, then retry.
          final refreshed = await _authService.refreshTokens();
          if (refreshed) {
            final newToken = _authService.accessToken;
            final opts = error.requestOptions;
            if (newToken != null) {
              opts.headers['Authorization'] = 'Bearer $newToken';
            }
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (_) {}
          }
          // Refresh failed → onSessionExpired already fired in AuthService.
          return handler.next(error);
        }
        handler.next(error);
      },
    ));
  }

  // ── Base URL ───────────────────────────────────────────────────────────────

  static String _resolveBaseUrl() {
    final url = AppEnv.apiBaseUrl;
    if (url.isEmpty) return 'https://nekologistic.lauraneval.dev';
    return _normalizeBaseUrl(url);
  }

  static String _normalizeBaseUrl(String baseUrl) {
    if (baseUrl.isEmpty) return baseUrl;
    try {
      final uri = Uri.parse(baseUrl);
      if (Platform.isAndroid &&
          (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        return uri.replace(host: '10.0.2.2').toString();
      }
    } catch (_) {}
    return baseUrl;
  }
}
