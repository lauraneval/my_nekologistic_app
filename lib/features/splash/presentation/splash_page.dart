import 'package:flutter/material.dart';

import '../../../bootstrap/app_bootstrap.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/presentation/login_page.dart';
import '../../mobile/presentation/mobile_shell_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.authService,
    required this.apiClient,
  });

  final AuthService authService;
  final ApiClient apiClient;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrapFlow();
  }

  Future<void> _bootstrapFlow() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) {
      return;
    }

    if (!AppBootstrap.isSupabaseInitialized) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _ConfigRequiredPage()),
      );
      return;
    }

    final targetPage = widget.authService.hasSession
      ? MobileShellPage(
            apiClient: widget.apiClient,
            authService: widget.authService,
          )
        : LoginPage(
            apiClient: widget.apiClient,
            authService: widget.authService,
          );

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => targetPage));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ConfigRequiredPage extends StatelessWidget {
  const _ConfigRequiredPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfigurasi Dibutuhkan')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Set dart-define berikut saat menjalankan app:\n\n'
          '- SUPABASE_URL\n'
          '- SUPABASE_ANON_KEY\n'
          '- API_BASE_URL',
        ),
      ),
    );
  }
}
