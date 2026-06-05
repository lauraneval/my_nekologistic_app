import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_service.dart';
import '../data/mobile_courier_repository.dart';
import '../domain/mobile_models.dart';
import 'mobile_task_detail_page.dart';
import 'mobile_profile_page.dart';

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
  late Future<MobileProfileResponse> _profileFuture;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchTaskBoard();
    _profileFuture = widget.repository.fetchProfile();
  }

  Future<void> refresh() async {
    setState(() {
      _future = widget.repository.fetchTaskBoard();
      _profileFuture = widget.repository.fetchProfile();
    });
    await Future.wait([_future, _profileFuture]);
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
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        toolbarHeight: 80,
        leadingWidth: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Home',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  ' / Task List',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('🅿️', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Text(
                  'NEKO',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            color: Colors.grey[600],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MobileProfilePage(
                      repository: widget.repository,
                      authService: widget.authService,
                      onLogout: widget.onLogout,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.orange[300],
                child: const Icon(Icons.person, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: FutureBuilder<MobileProfileResponse>(
          future: _profileFuture,
          builder: (context, profileSnapshot) {
            final courierName = profileSnapshot.data?.name ?? 'Kurir';

            return FutureBuilder<MobileTaskBoardResponse>(
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
                  return const _EmptyState(
                    message: 'Data dashboard belum tersedia.',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // Greeting section
                    _GreetingSection(
                      summary: data.summary,
                      courierName: courierName,
                    ),
                    const SizedBox(height: 24),

                    // Main summary strip (Total Distance + Remaining Drops)
                    _MainSummaryStrip(summary: data.summary),
                    const SizedBox(height: 24),

                    // Additional metrics grid
                    _MetricsGrid(summary: data.summary),
                    const SizedBox(height: 24),

                    // Active Tasks header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Delivery Tasks',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (data.activeTasks.isEmpty)
                      const _EmptyState(message: 'Tidak ada active task.')
                    else
                      ...data.activeTasks.map(
                        (task) => _NewTaskCard(
                          task: task,
                          onNavigate: () => _openMaps(task),
                          onOpenDetail: () => _openDetail(task),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.summary, required this.courierName});

  final MobileDashboardSummary summary;
  final String courierName;

  @override
  Widget build(BuildContext context) {
    final totalScheduled = summary.activeTasks + summary.queueTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Semangat pagi, $courierName!',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'You have $totalScheduled deliveries scheduled for today.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _MainSummaryStrip extends StatelessWidget {
  const _MainSummaryStrip({required this.summary});

  final MobileDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL DISTANCE\nTODAY',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${summary.totalDistance.toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REMAINING\nDROPS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  summary.remainingDrops.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFFFF8C00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.summary});

  final MobileDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: [
        _MetricCard(
          label: 'Delivered Today',
          value: summary.deliveredToday.toString(),
        ),
        _MetricCard(
          label: 'Active Tasks',
          value: summary.activeTasks.toString(),
        ),
        _MetricCard(label: 'Queue Tasks', value: summary.queueTasks.toString()),
        _MetricCard(
          label: 'Total Packages',
          value: summary.totalPackages.toString(),
        ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewTaskCard extends StatelessWidget {
  const _NewTaskCard({
    required this.task,
    required this.onNavigate,
    required this.onOpenDetail,
  });

  final MobileTaskItem task;
  final VoidCallback onNavigate;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: InkWell(
        onTap: onOpenDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task badge and status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.grey[100]),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SEDANG DIANTAR',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Task content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.recipientName ?? 'Unknown',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              task.recipientAddress ?? '-',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onNavigate,
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text('Navigate'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onOpenDetail,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            minimumSize: const Size.fromHeight(40),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(color: Color(0xFF2563EB)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
        Padding(padding: const EdgeInsets.all(24), child: Text(message)),
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
