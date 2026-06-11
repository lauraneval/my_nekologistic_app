import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userJsonKey = 'user_json';
  static const _expiresAtKey = 'expires_at';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (expiresAt != null) {
      await _storage.write(
          key: _expiresAtKey, value: expiresAt.toIso8601String());
    }
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<DateTime?> readExpiresAt() async {
    final val = await _storage.read(key: _expiresAtKey);
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  Future<void> saveUser(String userJson) =>
      _storage.write(key: _userJsonKey, value: userJson);

  Future<String?> readUser() => _storage.read(key: _userJsonKey);

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresAtKey),
      _storage.delete(key: _userJsonKey),
    ]);
  }
}
