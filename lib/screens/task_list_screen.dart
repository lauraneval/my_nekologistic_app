import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  double _computedDistanceKm = 0.0;
  bool _isComputingDistance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<TaskProvider>().loadTasks();
      if (mounted) {
        _showNewTaskDialogIfNeeded();
        _computeTotalDistance(context.read<TaskProvider>().activeTasks);
      }
    });
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dphi = (lat2 - lat1) * pi / 180;
    final dlambda = (lon2 - lon1) * pi / 180;
    final a =
        sin(dphi / 2) * sin(dphi / 2) +
        cos(phi1) * cos(phi2) * sin(dlambda / 2) * sin(dlambda / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<void> _computeTotalDistance(List<MobileTaskItem> tasks) async {
    final targets = tasks.where((t) => t.hasCoordinates).toList();
    if (targets.isEmpty) {
      if (mounted) setState(() => _computedDistanceKm = 0.0);
      return;
    }

    if (mounted) setState(() => _isComputingDistance = true);

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      double totalKm = 0.0;
      for (final task in targets) {
        totalKm += _haversineKm(
          pos.latitude,
          pos.longitude,
          task.latitude!,
          task.longitude!,
        );
      }

      if (mounted) setState(() => _computedDistanceKm = totalKm);
    } catch (_) {
      // GPS unavailable — keep current value
    } finally {
      if (mounted) setState(() => _isComputingDistance = false);
    }
  }

  void _showNewTaskDialogIfNeeded() {
    final provider = context.read<TaskProvider>();
    final newTasks = provider.newTasks;
    if (newTasks.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.activeOrange,
            ),
            const SizedBox(width: 8),
            Text(
              'New Package!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          newTasks.length == 1
              ? '1 new package has been queued.\nWould you like to start delivering now?'
              : '${newTasks.length} new packages have been queued.\nWould you like to start delivering now?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: dialogCtx.nekoTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearNewTasks();
              Navigator.pop(dialogCtx);
            },
            child: Text(
              'Later',
              style: GoogleFonts.inter(color: dialogCtx.nekoTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.activeOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              provider.clearNewTasks();
              for (final task in newTasks) {
                await provider.acceptTask(task.id);
              }
              if (mounted) await provider.loadTasks();
            },
            child: Text(
              'Deliver Now',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
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
            content: Text('Cannot open dialer: $phone'),
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
          onRefresh: () async {
            final taskProvider = context.read<TaskProvider>();
            await taskProvider.loadTasks();
            if (mounted) _computeTotalDistance(taskProvider.activeTasks);
          },
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
                    delegate: SliverChildBuilderDelegate((_, i) {
                      final task = tasks.activeTasks[i];
                      return ActiveTaskCard(
                        task: task,
                        onNavigate: () => _navigate(task),
                        onCall: () => _call(task),
                        onDetail: () =>
                            context.push('/tasks/${task.id}', extra: task),
                      );
                    }, childCount: tasks.activeTasks.length),
                  ),
                ),
                if (tasks.activeTasks.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: _EmptyCard(text: 'No active deliveries'),
                    ),
                  ),
                SliverToBoxAdapter(child: _buildMapThumbnail()),
                if (tasks.queueTasks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: _buildSectionHeader('Queue'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((_, i) {
                        final task = tasks.queueTasks[i];
                        return QueueTaskCard(
                          task: task,
                          onDetail: () =>
                              context.push('/tasks/${task.id}', extra: task),
                          onCall:
                              (task.recipientPhone != null &&
                                  task.recipientPhone != '-')
                              ? () => _call(task)
                              : null,
                        );
                      }, childCount: tasks.queueTasks.length),
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
        const Icon(
          Icons.local_shipping_rounded,
          color: AppColors.primaryBlue,
          size: 22,
        ),
        const SizedBox(width: 6),
        Text(
          'NekoLogistic',
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

  Widget _buildGreeting(
    BuildContext context,
    AuthProvider auth,
    MobileTaskBoardResponse? board,
  ) {
    final total =
        (board?.summary.activeTasks ?? 0) + (board?.summary.queueTasks ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Courier!',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.nekoTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.nekoTextSecondary,
            ),
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
                const Icon(
                  Icons.route_outlined,
                  color: Colors.white70,
                  size: 22,
                ),
                const SizedBox(height: 8),
                _isComputingDistance
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white70,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        '${_computedDistanceKm.toStringAsFixed(1)} km',
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
            decoration: context.nekoCardDecor(),
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
                    color: context.nekoTextSecondary,
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
            color: context.nekoTextPrimary,
          ),
        ),
        Icon(
          Icons.filter_list_rounded,
          color: context.nekoTextSecondary,
          size: 20,
        ),
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
            child: Icon(
              Icons.map_outlined,
              size: 60,
              color: Colors.white.withValues(alpha: 0.6),
            ),
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
        child: Text(
          msg,
          style: GoogleFonts.inter(color: AppColors.errorRed, fontSize: 14),
          textAlign: TextAlign.center,
        ),
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
      decoration: context.nekoCardDecor(),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: context.nekoTextSecondary,
          ),
        ),
      ),
    );
  }
}
