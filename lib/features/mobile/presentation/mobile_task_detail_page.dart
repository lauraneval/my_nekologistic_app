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
      appBar: AppBar(
        title: const Text('Task Detail'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
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
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          context,
                          'Weight',
                          '${task.weightKg?.toStringAsFixed(1) ?? '-'} kg',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'Handling Instruction',
                          task.handlingInstruction ?? '-',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'Expected Arrival',
                          task.expectedArrival?.toLocal().toString() ?? '-',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'Recipient',
                          task.recipientName ?? '-',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'Address',
                          task.recipientAddress ?? '-',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'Coordinates',
                          '${task.latitude?.toStringAsFixed(6) ?? '-'}, ${task.longitude?.toStringAsFixed(6) ?? '-'}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: task.hasCoordinates
                            ? () => _navigate(task)
                            : null,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Navigate'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openProofPage(task),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Proof'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (task.proofUrl != null)
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Proof sudah diupload',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
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
        : 'Gagal memuat detail task.';
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
    return Center(child: Text(message));
  }
}
