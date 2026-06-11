import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_env.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../models/auth_tokens.dart';
import '../../../models/user_model.dart';

class AuthService {
  AuthService({required SecureStorageService secureStorageService})
      : _secureStorage = secureStorageService {
    _dio = Dio(BaseOptions(
      baseUrl: _resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
    ));
  }

  final SecureStorageService _secureStorage;
  late final Dio _dio;

  AuthTokens? _tokens;
  UserModel? _currentUser;
  bool _initialized = false;

  /// Called by AuthProvider when the token is invalidated and the app must
  /// navigate back to the login screen.
  VoidCallback? onSessionExpired;

  UserModel? get currentUser => _currentUser;
  String? get accessToken => _tokens?.accessToken;

  bool get hasSession {
    final token = _tokens?.accessToken;
    return token != null && token.isNotEmpty;
  }

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Loads stored tokens on app start. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final accessToken = await _secureStorage.readAccessToken();
    final refreshToken = await _secureStorage.readRefreshToken();
    final userJson = await _secureStorage.readUser();
    final expiresAt = await _secureStorage.readExpiresAt();

    if (accessToken == null || accessToken.isEmpty) return;

    if (userJson != null) {
      try {
        _currentUser = UserModel.fromRawJson(userJson);
      } catch (_) {}
    }

    // Token still valid — restore in memory.
    if (expiresAt != null && DateTime.now().isBefore(expiresAt)) {
      _tokens = AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
        expiresIn: 3600,
        createdAt: expiresAt.subtract(const Duration(seconds: 3540)),
      );
      return;
    }

    // Token expired — try silent refresh.
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await refreshTokens(storedRefreshToken: refreshToken);
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/mobile/auth/login',
        data: {'email': email, 'password': password},
      );
      await _applyTokenResponse(response.data);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    final token = _tokens?.accessToken;
    try {
      if (token != null && token.isNotEmpty) {
        await _dio.post(
          '/mobile/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (_) {}
    await _clearSession();
  }

  // ── Token refresh ──────────────────────────────────────────────────────────

  /// Returns true if refresh succeeded. Fires [onSessionExpired] on failure.
  Future<bool> refreshTokens({String? storedRefreshToken}) async {
    final rt = storedRefreshToken ?? _tokens?.refreshToken;
    if (rt == null || rt.isEmpty) {
      await _clearSession();
      onSessionExpired?.call();
      return false;
    }

    try {
      final response = await _dio.post(
        '/mobile/auth/refresh',
        data: {'refresh_token': rt},
      );
      await _applyTokenResponse(response.data);
      return true;
    } catch (_) {
      await _clearSession();
      onSessionExpired?.call();
      return false;
    }
  }

  // ── Bearer token for ApiClient ─────────────────────────────────────────────

  Future<String?> getBearerToken() async {
    // If in-memory token exists and is fresh, return it immediately.
    if (_tokens != null && !_tokens!.isExpired) {
      return _tokens!.accessToken;
    }

    // No in-memory token — try storage.
    if (_tokens == null) {
      final stored = await _secureStorage.readAccessToken();
      if (stored == null || stored.isEmpty) return null;
      final expiresAt = await _secureStorage.readExpiresAt();
      if (expiresAt != null && DateTime.now().isBefore(expiresAt)) {
        return stored;
      }
    }

    // Expired — try refresh.
    final refreshed = await refreshTokens();
    return refreshed ? _tokens?.accessToken : null;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _applyTokenResponse(dynamic responseData) async {
    final data = _extractData(responseData);
    _tokens = AuthTokens.fromJson(data);

    final userJson = data['user'];
    if (userJson is Map<String, dynamic>) {
      _currentUser = UserModel.fromJson(userJson);
      await _secureStorage.saveUser(_currentUser!.toRawJson());
    }

    await _secureStorage.saveTokens(
      accessToken: _tokens!.accessToken,
      refreshToken: _tokens!.refreshToken,
      expiresAt: _tokens!.expiresAt,
    );
  }

  Future<void> _clearSession() async {
    _tokens = null;
    _currentUser = null;
    _initialized = false;
    await _secureStorage.clearTokens();
  }

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) return data;
      return responseData;
    }
    return {};
  }

  String _extractErrorMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi timeout. Periksa jaringan internet kamu.';
    }
    return e.message ?? 'Request gagal.';
  }

  static String _resolveBaseUrl() {
    final url = AppEnv.apiBaseUrl;
    if (url.isEmpty) return 'https://nekologistic.lauraneval.dev';
    // Normalize localhost → 10.0.2.2 on Android emulator
    try {
      final uri = Uri.parse(url);
      if (Platform.isAndroid &&
          (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        return uri.replace(host: '10.0.2.2').toString();
      }
    } catch (_) {}
    return url;
  }
}
