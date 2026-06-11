import 'package:dio/dio.dart';

import '../core/config/app_env.dart';
import '../core/storage/secure_storage_service.dart';

/// Tracks courier activity by updating last_login_at via the REST API.
/// Throttled to at most one write per 5 minutes, except on explicit sign-in.
class SessionService {
  static DateTime? _lastUpdate;
  static const _throttle = Duration(minutes: 5);

  static Future<void> updateLastSeen({bool force = false}) async {
    final now = DateTime.now().toUtc();
    if (!force &&
        _lastUpdate != null &&
        now.difference(_lastUpdate!) < _throttle) {
      return;
    }

    try {
      final storage = SecureStorageService();
      final token = await storage.readAccessToken();
      if (token == null || token.isEmpty) return;

      _lastUpdate = now;

      await Dio().patch(
        '${AppEnv.apiBaseUrl}/mobile/profile',
        data: {'last_login_at': now.toIso8601String()},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
    } catch (_) {
      // Non-critical — never interrupt the user flow.
    }
  }
}
