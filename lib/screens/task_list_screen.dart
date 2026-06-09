import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../features/mobile/domain/mobile_models.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<TaskProvider>().loadTasks();
      if (mounted) _showNewTaskDialogIfNeeded();
    });
  }

  void _showNewTaskDialogIfNeeded() {
    final provider = context.read<TaskProvider>();
    final newTasks = provider.newTasks;
    if (newTasks.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: AppColors.activeOrange),
            const SizedBox(width: 8),
            Text(
              'Paket Baru!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          newTasks.length == 1
              ? 'Ada 1 paket baru masuk ke antrian.\nIngin mulai mengantar sekarang?'
              : 'Ada ${newTasks.length} paket baru masuk.\nIngin mulai mengantar sekarang?',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearNewTasks();
              Navigator.pop(context);
            },
            child: Text('Nanti', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.activeOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              provider.clearNewTasks();
              for (final task in newTasks) {
                await provider.acceptTask(task.id);
              }
              await provider.loadTasks();
            },
            child: Text('Antar Sekarang', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _navigate(MobileTaskItem task) async {
    if (!task.hasCoordinates) return;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${task.latitude},${task.longitude}',
    );
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _call(MobileTaskItem task) async {
    final phone = task.recipientPhone;
    if (phone == null || phone == '-') return;
    final url = Uri.parse('tel:$phone');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka dialer: $phone'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    final auth = context.watch<AuthProvider>();
    final board = tasks.board;
    final summary = board?.summary;

    return Scaffold(
      body: LoadingOverlay(
        isLoading: tasks.isLoading && board == null,
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () => context.read<TaskProvider>().loadTasks(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(context, auth),
                      const SizedBox(height: 20),
                      _buildGreeting(context, auth, board),
                      const SizedBox(height: 16),
                      _buildStatsRow(summary),
                    ],
                  ),
                ),
              ),
              if (tasks.error != null)
                SliverToBoxAdapter(child: _buildError(tasks.error!))
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: _buildSectionHeader('Active Delivery Tasks'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final task = tasks.activeTasks[i];
                        return ActiveTaskCard(
                          task: task,
                          onNavigate: () => _navigate(task),
                          onCall: () => _call(task),
                          onDetail: () => context.push('/tasks/${task.id}', extra: task),
                        );
                      },
                      childCount: tasks.activeTasks.length,
                    ),
                  ),
                ),
                if (tasks.activeTasks.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: _EmptyCard(text: 'Tidak ada pengiriman aktif'),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _buildMapThumbnail(),
                ),
                if (tasks.queueTasks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: _buildSectionHeader('Antrian'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final task = tasks.queueTasks[i];
                          return QueueTaskCard(
                            task: task,
                            onDetail: () => context.push('/tasks/${task.id}', extra: task),
                            onCall: (task.recipientPhone != null && task.recipientPhone != '-')
                                ? () => _call(task)
                                : null,
                          );
                        },
                        childCount: tasks.queueTasks.length,
                      ),
                    ),
                  ),
                ] else
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AuthProvider auth) {
    return Row(
      children: [
        const Icon(Icons.local_shipping_rounded, color: AppColors.primaryBlue, size: 22),
        const SizedBox(width: 6),
        Text(
          'NEKO',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryBlue,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context, AuthProvider auth, MobileTaskBoardResponse? board) {
    final total = (board?.summary.activeTasks ?? 0) + (board?.summary.queueTasks ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Semangat pagi, Kurir!',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            children: [
              const TextSpan(text: 'You have '),
              TextSpan(
                text: '$total deliveries',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' scheduled for today.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(MobileDashboardSummary? summary) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.route_outlined, color: Colors.white70, size: 22),
                const SizedBox(height: 8),
                Text(
                  '${summary?.totalDistanceKm.toStringAsFixed(1) ?? '0.0'} km',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TOTAL DISTANCE TODAY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: nekoCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary?.remainingDrop ?? 0}'.padLeft(2, '0'),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.activeOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'REMAINING\nDROPS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Icon(Icons.filter_list_rounded, color: AppColors.textSecondary, size: 20),
      ],
    );
  }

  Widget _buildMapThumbnail() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.map_outlined, size: 60, color: Colors.white.withValues(alpha: 0.6)),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT OPTIMIZATION',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'Cluster B Route',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(msg,
            style: GoogleFonts.inter(color: AppColors.errorRed, fontSize: 14),
            textAlign: TextAlign.center),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: nekoCardDecoration(),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
