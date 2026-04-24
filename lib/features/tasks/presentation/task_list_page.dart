import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_service.dart';
import '../domain/courier_task.dart';
import 'task_detail_page.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  final ApiClient apiClient;
  final AuthService authService;

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  late Future<List<CourierTask>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _fetchPendingTasks();
  }

  Future<List<CourierTask>> _fetchPendingTasks() async {
    final response = await widget.apiClient.get(
      '/courier/tasks',
      queryParameters: {'status': 'OUT_FOR_DELIVERY'},
    );

    final payload = response.data;
    List<dynamic> rawTasks = <dynamic>[];

    if (payload is List<dynamic>) {
      rawTasks = payload;
    } else if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      final items = payload['items'];
      if (data is List<dynamic>) {
        rawTasks = data;
      } else if (items is List<dynamic>) {
        rawTasks = items;
      }
    }

    return rawTasks
        .whereType<Map<String, dynamic>>()
        .map(CourierTask.fromJson)
        .where((task) => task.status != 'DELIVERED')
        .toList(growable: false);
  }

  Future<void> _refreshTasks() async {
    setState(() {
      _tasksFuture = _fetchPendingTasks();
    });
    await _tasksFuture;
  }

  Future<void> _openMaps(CourierTask task) async {
    final query = task.hasCoordinates
        ? '${task.latitude},${task.longitude}'
        : task.address;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka Google Maps.')),
      );
    }
  }

  Future<void> _signOut() async {
    await widget.authService.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openTaskDetail(CourierTask task) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskDetailPage(task: task, apiClient: widget.apiClient),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await _refreshTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas Kurir'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: FutureBuilder<List<CourierTask>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Terjadi error saat mengambil data tugas: ${snapshot.error}',
                    ),
                  ),
                ],
              );
            }

            final tasks = snapshot.data ?? <CourierTask>[];
            if (tasks.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.inbox_outlined, size: 64),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Belum ada paket untuk diantar.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.recipientName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.resi,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(task.address),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () => _openMaps(task),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Arahkan'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _openTaskDetail(task),
                              child: const Text('Detail'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
