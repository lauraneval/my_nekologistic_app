import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_service.dart';
import 'features/mobile/data/mobile_courier_api_client.dart';
import 'features/mobile/data/mobile_courier_repository.dart';
import 'features/mobile/data/proof_upload_service.dart';
import 'providers/auth_provider.dart';
import 'providers/history_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/task_provider.dart';
import 'router/app_router.dart';
import 'services/api_service.dart';
import 'services/session_service.dart';

class NekoLogisticApp extends StatefulWidget {
  const NekoLogisticApp({super.key});

  @override
  State<NekoLogisticApp> createState() => _NekoLogisticAppState();
}

class _NekoLogisticAppState extends State<NekoLogisticApp>
    with WidgetsBindingObserver {
  late final SecureStorageService _secureStorage;
  late final AuthService _authService;
  late final ApiClient _apiClient;
  late final MobileCourierRepository _repository;
  late final ApiService _apiService;
  late final AuthProvider _authProvider;
  late final TaskProvider _taskProvider;
  late final HistoryProvider _historyProvider;
  late final ProfileProvider _profileProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secureStorage = SecureStorageService();
    _authService = AuthService(secureStorageService: _secureStorage);
    _apiClient = ApiClient(authService: _authService);
    final mobileApiClient = MobileCourierApiClient(apiClient: _apiClient);
    _repository = MobileCourierRepository(apiClient: mobileApiClient);
    _apiService = ApiService(
      repository: _repository,
      proofUploadService: ProofUploadService(),
    );
    _authProvider = AuthProvider(authService: _authService);
    _taskProvider = TaskProvider(apiService: _apiService);
    _historyProvider = HistoryProvider(apiService: _apiService);
    _profileProvider = ProfileProvider(apiService: _apiService);
    _router = buildRouter(_authProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SessionService.updateLastSeen();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authProvider.dispose();
    _taskProvider.dispose();
    _historyProvider.dispose();
    _profileProvider.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _taskProvider),
        ChangeNotifierProvider.value(value: _historyProvider),
        ChangeNotifierProvider.value(value: _profileProvider),
        Provider<ApiService>.value(value: _apiService),
      ],
      child: Consumer<ProfileProvider>(
        builder: (_, profile, _) => Listener(
          onPointerDown: (_) => SessionService.updateLastSeen(),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'NekoLogistic Courier',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: profile.darkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
