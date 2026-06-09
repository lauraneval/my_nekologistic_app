import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../bootstrap/app_bootstrap.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../services/session_service.dart';

class AuthService {
  AuthService({required SecureStorageService secureStorageService})
    : _secureStorageService = secureStorageService;

  final SecureStorageService _secureStorageService;

  bool get hasSession {
    if (!AppBootstrap.isSupabaseInitialized) {
      return false;
    }
    return Supabase.instance.client.auth.currentSession != null;
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!AppBootstrap.isSupabaseInitialized) {
      throw StateError('Supabase belum dikonfigurasi.');
    }

    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final session = response.session;
    if (session == null) {
      throw StateError('Session tidak ditemukan setelah login.');
    }

    await _secureStorageService.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
    );

    await SessionService.updateLastSeen(force: true);
  }

  Future<void> signOut() async {
    if (AppBootstrap.isSupabaseInitialized) {
      await Supabase.instance.client.auth.signOut();
    }
    await _secureStorageService.clearTokens();
  }

  Future<String?> getBearerToken() async {
    if (AppBootstrap.isSupabaseInitialized) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _secureStorageService.saveTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken ?? '',
        );
        return session.accessToken;
      }
    }

    return _secureStorageService.readAccessToken();
  }
}
