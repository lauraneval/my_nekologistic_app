import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/mobile/domain/mobile_models.dart';
import '../providers/auth_provider.dart';
import '../screens/geofence_validation_screen.dart';
import '../screens/history_screen.dart';
import '../screens/login_screen.dart';
import '../screens/pod_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/task_detail_screen.dart';
import '../screens/task_list_screen.dart';
import '../widgets/bottom_nav_bar.dart';

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/tasks',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggedIn = authProvider.isLoggedIn;
      final loading = authProvider.isLoading;
      if (loading) return null;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/tasks';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (_, _) => const TaskListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => TaskDetailScreen(
                      taskId: state.pathParameters['id']!,
                      initialTask: state.extra as MobileTaskItem?,
                    ),
                    routes: [
                      GoRoute(
                        path: 'geofence',
                        builder: (context, state) => GeofenceValidationScreen(
                          taskId: state.pathParameters['id']!,
                          task: state.extra as MobileTaskItem?,
                        ),
                      ),
                      GoRoute(
                        path: 'pod',
                        builder: (context, state) => PodScreen(
                          taskId: state.pathParameters['id']!,
                          task: state.extra as MobileTaskItem?,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, _) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'privacy',
                    builder: (_, _) => const PrivacyScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _MainShell extends StatelessWidget {
  const _MainShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NekoBottomNavBar(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
      ),
    );
  }
}
