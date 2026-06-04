import 'package:flutter/material.dart';

import '../data/mobile_courier_repository.dart';
import '../domain/mobile_models.dart';

class MobileHistoryPage extends StatefulWidget {
  const MobileHistoryPage({super.key, required this.repository});

  final MobileCourierRepository repository;

  @override
  State<MobileHistoryPage> createState() => _MobileHistoryPageState();
}

class _MobileHistoryPageState extends State<MobileHistoryPage> {
  late Future<MobileHistoryResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repository.fetchHistory();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<MobileHistoryResponse>(
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
              return const _EmptyState(message: 'History belum tersedia.');
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HistorySection(title: 'Hari Ini', items: data.today),
                const SizedBox(height: 16),
                _HistorySection(title: 'Kemarin', items: data.yesterday),
                const SizedBox(height: 16),
                _HistorySection(title: '7 Hari Terakhir', items: data.last7Days),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.title, required this.items});

  final String title;
  final List<MobileTaskItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('Belum ada item delivered.')
            else
              ...items.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.title),
                            const SizedBox(height: 2),
                            Text(task.recipientName ?? task.recipientAddress ?? '-'),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    final message = error is MobileApiException ? (error as MobileApiException).message : 'Gagal memuat history.';
    return ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(message))]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}