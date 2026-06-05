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
  String _selectedFilter = 'today'; // today, yesterday, last7days

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

  List<MobileTaskItem> _getFilteredItems(MobileHistoryResponse data) {
    switch (_selectedFilter) {
      case 'today':
        return data.today;
      case 'yesterday':
        return data.yesterday;
      case 'last7days':
        return data.last7Days;
      default:
        return data.today;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
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

            final filteredItems = _getFilteredItems(data);
            final totalDelivered =
                data.today.length +
                data.yesterday.length +
                data.last7Days.length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery History',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tracking your completed logistical movements',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterButton(
                        label: 'Today',
                        isSelected: _selectedFilter == 'today',
                        onPressed: () =>
                            setState(() => _selectedFilter = 'today'),
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(
                        label: 'Yesterday',
                        isSelected: _selectedFilter == 'yesterday',
                        onPressed: () =>
                            setState(() => _selectedFilter = 'yesterday'),
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(
                        label: 'Last 7 Days',
                        isSelected: _selectedFilter == 'last7days',
                        onPressed: () =>
                            setState(() => _selectedFilter = 'last7days'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MONTHLY TOTAL',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$totalDelivered',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2563EB),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '+12%',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.green[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 1,
                        color: const Color(0xFF2563EB),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EFFICIENCY SCORE',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '98.4%',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // History Items
                if (filteredItems.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Belum ada item delivered',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HistoryItem(item: item),
                    ),
                  ),

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.expand_more),
                  label: const Text('Load More History'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFF2563EB)
            : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.grey[800],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.item});

  final MobileTaskItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.business, color: Colors.blue[700], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.recipientName ?? item.title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DELIVERED',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.tag, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'ID: ${item.title}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Oct 24, 2023 • 14:32',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
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
        : 'Gagal memuat history.';
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
  Widget build(BuildContext context) => Center(child: Text(message));
}
