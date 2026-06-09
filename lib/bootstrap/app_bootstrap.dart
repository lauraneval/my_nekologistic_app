import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_env.dart';
import '../services/notification_service.dart';

class AppBootstrap {
  static bool _supabaseInitialized = false;

  static bool get isSupabaseInitialized => _supabaseInitialized;

  static Future<void> initialize() async {
    if (AppEnv.supabaseUrl.isEmpty || AppEnv.supabaseAnonKey.isEmpty) {
      debugPrint(
        'Supabase configuration is missing. Set --dart-define SUPABASE_URL and SUPABASE_ANON_KEY.',
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
    await NotificationService.initialize();
  }
}
