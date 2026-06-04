import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/presentation/login_page.dart';
import '../data/mobile_courier_api_client.dart';
import '../data/mobile_courier_repository.dart';
import 'mobile_history_page.dart';
import 'mobile_home_page.dart';
import 'mobile_profile_page.dart';

class MobileShellPage extends StatefulWidget {
  const MobileShellPage({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  final ApiClient apiClient;
  final AuthService authService;

  @override
  State<MobileShellPage> createState() => _MobileShellPageState();
}

class _MobileShellPageState extends State<MobileShellPage> {
  late final MobileCourierRepository _repository;
  late final GlobalKey<MobileHomePageState> _homeKey;
  late final List<Widget> _pages;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = MobileCourierRepository(
      apiClient: MobileCourierApiClient(apiClient: widget.apiClient),
    );
    _homeKey = GlobalKey<MobileHomePageState>();
    _pages = [
      MobileHomePage(
        key: _homeKey,
        repository: _repository,
        apiClient: widget.apiClient,
        authService: widget.authService,
        onTaskChanged: _refreshHome,
        onLogout: _handleLogout,
      ),
      MobileHistoryPage(repository: _repository),
      MobileProfilePage(
        repository: _repository,
        authService: widget.authService,
        onLogout: _handleLogout,
      ),
    ];
  }

  Future<void> _refreshHome() async {
    await _homeKey.currentState?.refresh();
  }

  Future<void> _handleLogout() async {
    await widget.authService.signOut();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          authService: widget.authService,
          apiClient: widget.apiClient,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}