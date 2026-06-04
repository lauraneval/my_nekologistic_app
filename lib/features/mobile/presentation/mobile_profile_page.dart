import 'package:flutter/material.dart';

import '../../auth/data/auth_service.dart';
import '../data/mobile_courier_repository.dart';
import '../domain/mobile_models.dart';

class MobileProfilePage extends StatefulWidget {
  const MobileProfilePage({
    super.key,
    required this.repository,
    required this.authService,
    required this.onLogout,
  });

  final MobileCourierRepository repository;
  final AuthService authService;
  final Future<void> Function() onLogout;

  @override
  State<MobileProfilePage> createState() => _MobileProfilePageState();
}

class _MobileProfilePageState extends State<MobileProfilePage> {
  late Future<MobileProfileResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchProfile();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repository.fetchProfile();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<MobileProfileResponse>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorState(error: snapshot.error);
            }

            final profile = snapshot.data;
            if (profile == null) {
              return const _EmptyState(message: 'Profile belum tersedia.');
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(profile.email),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _StatCard(label: 'Efficiency Score', value: profile.efficiencyScore.toStringAsFixed(1)),
                _StatCard(label: 'Total Packages', value: profile.totalPackages.toString()),
                _StatCard(label: 'Delivered Packages', value: profile.deliveredPackages.toString()),
                _StatCard(label: 'Active Tasks', value: profile.activeTasks.toString()),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final message = error is MobileApiException ? (error as MobileApiException).message : 'Gagal memuat profile.';
    return ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(message))]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}