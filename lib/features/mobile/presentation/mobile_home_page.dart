import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_service.dart';
import '../data/mobile_courier_repository.dart';
import '../domain/mobile_models.dart';
import 'mobile_task_detail_page.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({
    super.key,
    required this.repository,
    required this.apiClient,
    required this.authService,
    required this.onTaskChanged,
    required this.onLogout,
  });

  final MobileCourierRepository repository;
  final ApiClient apiClient;
  final AuthService authService;
  final Future<void> Function() onTaskChanged;
  final Future<void> Function() onLogout;

  @override
  State<MobileHomePage> createState() => MobileHomePageState();
}

class MobileHomePageState extends State<MobileHomePage> {
  late Future<MobileTaskBoardResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchTaskBoard();
  }

  Future<void> refresh() async {
    setState(() {
      _future = widget.repository.fetchTaskBoard();
    });
    await _future;
  }

  Future<void> _openMaps(MobileTaskItem task) async {
    final query = task.hasCoordinates
        ? '${task.latitude},${task.longitude}'
        : task.recipientAddress ?? task.title;

    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openDetail(MobileTaskItem task) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MobileTaskDetailPage(
          taskId: task.id,
          repository: widget.repository,
          apiClient: widget.apiClient,
          onTaskChanged: widget.onTaskChanged,
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Kurir'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: FutureBuilder<MobileTaskBoardResponse>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorState(error: snapshot.error);
            }

            final data = snapshot.data;
            if (data == null) {
              return const _EmptyState(message: 'Data dashboard belum tersedia.');
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryStrip(summary: data.summary),
                const SizedBox(height: 16),
                Text('Active Tasks', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (data.activeTasks.isEmpty)
                  const _EmptyState(message: 'Tidak ada active task.')
                else
                  ...data.activeTasks.map(
                    (task) => _TaskCard(
                      task: task,
                      onNavigate: () => _openMaps(task),
                      onOpenDetail: () => _openDetail(task),
                      accent: Colors.green,
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Queue Tasks', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (data.queueTasks.isEmpty)
                  const _EmptyState(message: 'Queue task kosong.')
                else
                  ...data.queueTasks.map(
                    (task) => _TaskCard(
                      task: task,
                      onNavigate: () => _openMaps(task),
                      onOpenDetail: () => _openDetail(task),
                      accent: Colors.orange,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

  final MobileDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.9,
      children: [
        _MetricCard(label: 'Delivered Today', value: summary.deliveredToday.toString()),
        _MetricCard(label: 'Active Tasks', value: summary.activeTasks.toString()),
        _MetricCard(label: 'Queue Tasks', value: summary.queueTasks.toString()),
        _MetricCard(label: 'Total Packages', value: summary.totalPackages.toString()),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onNavigate,
    required this.onOpenDetail,
    required this.accent,
  });

  final MobileTaskItem task;
  final VoidCallback onNavigate;
  final VoidCallback onOpenDetail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(task.recipientName ?? task.recipientAddress ?? '-'),
                    ],
                  ),
                ),
                Chip(label: Text(task.status), backgroundColor: accent.withValues(alpha: 0.12)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Weight: ${task.weightKg?.toStringAsFixed(1) ?? '-'} kg'),
            Text('Expected arrival: ${task.expectedArrival?.toLocal().toString() ?? '-'}'),
            Text('Handling: ${task.handlingInstruction ?? '-'}'),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Navigate'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onOpenDetail,
                  child: const Text('Detail'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final message = error is MobileApiException
        ? (error as MobileApiException).message
        : 'Terjadi error saat memuat dashboard.';

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(message)),
    );
  }
}