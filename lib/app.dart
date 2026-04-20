import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/auth_service.dart';
import 'features/splash/presentation/splash_page.dart';

class NekoLogisticApp extends StatelessWidget {
  const NekoLogisticApp({super.key});

  @override
  Widget build(BuildContext context) {
    final secureStorage = SecureStorageService();
    final authService = AuthService(secureStorageService: secureStorage);
    final apiClient = ApiClient(authService: authService);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NekoLogistic Courier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF166534)),
        useMaterial3: true,
      ),
      home: SplashPage(authService: authService, apiClient: apiClient),
    );
  }
}
