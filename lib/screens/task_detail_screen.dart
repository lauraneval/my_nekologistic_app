import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../features/mobile/domain/mobile_models.dart';
import '../providers/task_provider.dart';
import '../widgets/status_badge.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId, this.initialTask});

  final String taskId;
  final MobileTaskItem? initialTask;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    // When a specific task is already provided (navigated from task list or geofence),
    // skip the API fetch. The fetch uses the bag ID and would return the bag's first
    // package, overwriting the correct package the user tapped on.
    if (widget.initialTask == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TaskProvider>().loadTaskDetail(widget.taskId);
      });
    }
  }

  Future<void> _callPhone(String? phone) async {
    if (phone == null || phone == '-') return;
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$digits');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _navigateTo(MobileTaskItem task) async {
    if (!task.hasCoordinates) return;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${task.latitude},${task.longitude}',
    );
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    // Prefer initialTask when provided — it is the exact package the user tapped.
    // Fall back to provider.currentTask only when accessed without a preloaded task
    // (e.g. deep link or direct URL access).
    final task = widget.initialTask ?? provider.currentTask;

    return Scaffold(
      body: provider.isDetailLoading && task == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : task == null
              ? _buildError(provider.error ?? 'Task not found')
              : _buildContent(task),
    );
  }

  Widget _buildContent(MobileTaskItem task) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              _buildMapArea(task),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: context.nekoInputFill,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: context.nekoInputFill,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PACKAGE DELIVERY',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.nekoTextSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeroSection(task),
              const SizedBox(height: 16),
              _buildRecipientCard(task),
              const SizedBox(height: 12),
              _buildSenderCard(task),
              const SizedBox(height: 12),
              _buildPackageCard(task),
              const SizedBox(height: 12),
              _buildAddressCard(task),
              const SizedBox(height: 24),
              _buildMarkDeliveredButton(task),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMapArea(MobileTaskItem task) {
    return Container(
      height: 260,
      color: const Color(0xFF2D3748),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.map_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _navigateTo(task),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.navigation_outlined,
                        color: AppColors.primaryBlue, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Navigate to Location',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(MobileTaskItem task) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '#${task.title}',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.nekoTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(status: task.status),
      ],
    );
  }

  Widget _buildRecipientCard(MobileTaskItem task) {
    final phone = task.recipientPhone;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.nekoCardDecor(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECIPIENT',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.nekoTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.recipientName ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.nekoTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                _contactRow(
                  Icons.phone_outlined,
                  phone ?? '-',
                  onTap: phone != null ? () => _callPhone(phone) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderCard(MobileTaskItem task) {
    final phone = task.senderPhone;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.nekoCardDecor(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.store_outlined, color: AppColors.successGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SENDER',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.nekoTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.senderName ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.nekoTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                _contactRow(
                  Icons.phone_outlined,
                  phone ?? '-',
                  onTap: phone != null ? () => _callPhone(phone) : null,
                ),
                const SizedBox(height: 4),
                _contactRow(Icons.email_outlined, task.senderEmail ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String value, {VoidCallback? onTap}) {
    final row = Row(
      children: [
        Icon(icon, size: 14, color: context.nekoTextSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: onTap != null ? AppColors.primaryBlue : context.nekoTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onTap != null)
          const Icon(Icons.call_outlined, size: 14, color: AppColors.primaryBlue),
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(onTap: onTap, child: row);
  }

  Widget _buildPackageCard(MobileTaskItem task) {
    final handling = task.handlingInstruction;
    final isCareful = handling?.toLowerCase() == 'careful' ||
        handling?.toLowerCase() == 'fragile';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.nekoCardDecor(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.activeOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.activeOrange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PACKAGE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.nekoTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.packageName ?? task.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.nekoTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoChip('WEIGHT', '${task.weightKg?.toStringAsFixed(1) ?? '-'} kg'),
                    const SizedBox(width: 20),
                  ],
                ),
                if (task.lengthCm != null || task.widthCm != null || task.heightCm != null) ...[
                  const SizedBox(height: 8),
                  _infoChip(
                    'DIMENSIONS',
                    '${task.lengthCm?.toStringAsFixed(0) ?? '-'} × '
                    '${task.widthCm?.toStringAsFixed(0) ?? '-'} × '
                    '${task.heightCm?.toStringAsFixed(0) ?? '-'} cm',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: context.nekoTextSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? context.nekoTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(MobileTaskItem task) {
    final arrival = task.expectedArrival;
    final timeStr = arrival != null
        ? '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}'
        : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.nekoCardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DELIVERY ADDRESS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.nekoTextSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.location_on_outlined,
                  color: AppColors.primaryBlue, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.recipientAddress ?? '-',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.nekoTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkDeliveredButton(MobileTaskItem task) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () =>
            context.push('/tasks/${task.id}/pod', extra: task),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.activeOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 20),
            const SizedBox(width: 8),
            Text(
              'Mark as Delivered',
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
            const SizedBox(height: 12),
            Text(msg,
                style: GoogleFonts.inter(color: context.nekoTextSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
