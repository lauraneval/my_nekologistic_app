import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_env.dart';
import '../services/notification_service.dart';

/// App initialization.
///
/// Supabase is kept ONLY for Storage (POD photo uploads).
/// Authentication is handled entirely via the REST API — no Supabase auth sessions.
class AppBootstrap {
  static bool _supabaseInitialized = false;

  static bool get isSupabaseInitialized => _supabaseInitialized;

  static Future<void> initialize() async {
    await NotificationService.initialize();

    if (AppEnv.supabaseUrl.isEmpty || AppEnv.supabaseAnonKey.isEmpty) {
      debugPrint(
        '[AppBootstrap] Supabase config missing — POD photo uploads will fail. '
        'Pass --dart-define SUPABASE_URL and SUPABASE_ANON_KEY to enable storage.',
      );
      return;
    }

    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _supabaseInitialized = true;
  }
}
