import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../data/mobile_courier_repository.dart';
import '../domain/mobile_models.dart';
import 'mobile_delivery_proof_page.dart';

class MobileTaskDetailPage extends StatefulWidget {
  const MobileTaskDetailPage({
    super.key,
    required this.taskId,
    required this.repository,
    required this.apiClient,
    required this.onTaskChanged,
  });

  final String taskId;
  final MobileCourierRepository repository;
  final ApiClient apiClient;
  final Future<void> Function() onTaskChanged;

  @override
  State<MobileTaskDetailPage> createState() => _MobileTaskDetailPageState();
}

class _MobileTaskDetailPageState extends State<MobileTaskDetailPage> {
  late Future<MobileTaskDetailResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchTaskDetail(widget.taskId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repository.fetchTaskDetail(widget.taskId);
    });
    await _future;
  }

  Future<void> _openProofPage(MobileTaskItem task) async {
    final delivered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MobileDeliveryProofPage(
          task: task,
          repository: widget.repository,
          apiClient: widget.apiClient,
        ),
      ),
    );

    if (delivered == true) {
      await _refresh();
      await widget.onTaskChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Detail')),
      body: FutureBuilder<MobileTaskDetailResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error);
          }

          final task = snapshot.data?.task;
          if (task == null) {
            return const _EmptyState(message: 'Task detail belum tersedia.');
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Weight: ${task.weightKg?.toStringAsFixed(1) ?? '-'} kg'),
                        const SizedBox(height: 6),
                        Text('Handling instruction: ${task.handlingInstruction ?? '-'}'),
                        const SizedBox(height: 6),
                        Text('Expected arrival: ${task.expectedArrival?.toLocal().toString() ?? '-'}'),
                        const SizedBox(height: 6),
                        Text('Destination coords: ${task.latitude?.toStringAsFixed(6) ?? '-'}, ${task.longitude?.toStringAsFixed(6) ?? '-'}'),
                        const SizedBox(height: 6),
                        Text('Recipient: ${task.recipientName ?? '-'}'),
                        const SizedBox(height: 6),
                        Text('Address: ${task.recipientAddress ?? '-'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: task.hasCoordinates
                      ? () => _navigate(task)
                      : null,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Navigate'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _openProofPage(task),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Proof of Delivery'),
                ),
                const SizedBox(height: 12),
                if (task.proofUrl != null) ...[
                  Text('Existing proof URL: ${task.proofUrl}'),
                ],
                const SizedBox(height: 8),
                Text(
                  'Backend yang memvalidasi radius 100 meter. Flutter hanya mengirim latitude, longitude, dan proof_url saat submit.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigate(MobileTaskItem task) async {
    final query = task.hasCoordinates
        ? '${task.latitude},${task.longitude}'
        : task.recipientAddress ?? task.title;
    final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final message = error is MobileApiException ? (error as MobileApiException).message : 'Gagal memuat detail task.';
    return ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(message))]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}