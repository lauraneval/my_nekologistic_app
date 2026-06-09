import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  static DateTime? _lastUpdate;
  static const _throttle = Duration(minutes: 5);

  /// Update last_login_at di tabel profiles.
  /// [force] = true untuk bypass throttle (dipakai saat sign in).
  static Future<void> updateLastSeen({bool force = false}) async {
    final now = DateTime.now().toUtc();
    if (!force &&
        _lastUpdate != null &&
        now.difference(_lastUpdate!) < _throttle) {
      return;
    }

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      _lastUpdate = now;
      await client
          .from('profiles')
          .update({'last_login_at': now.toIso8601String()})
          .eq('user_id', userId);
    } catch (_) {
      // Non-critical — jangan ganggu flow utama
    }
  }
}
