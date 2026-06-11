import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../features/mobile/domain/mobile_models.dart';
import 'status_badge.dart';

class ActiveTaskCard extends StatelessWidget {
  const ActiveTaskCard({
    super.key,
    required this.task,
    required this.onNavigate,
    required this.onCall,
    required this.onDetail,
  });

  final MobileTaskItem task;
  final VoidCallback onNavigate;
  final VoidCallback onCall;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetail,
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.nekoCardBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: const Border(
          left: BorderSide(color: AppColors.activeOrange, width: 4),
        ),
        boxShadow: context.isDark
            ? null
            : const [
                BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(status: task.status),
                const SizedBox(width: 8),
                Text(
                  task.bagCode ?? task.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.nekoTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.more_vert, color: context.nekoTextSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.nekoInputFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on_outlined,
                      color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.recipientName ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.nekoTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.recipientAddress ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.nekoTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onNavigate,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.navigation_outlined,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Navigate',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onCall,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.nekoInputFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.nekoDivider),
                    ),
                    child: Icon(
                      Icons.phone_outlined,
                      color: task.recipientPhone != null && task.recipientPhone != '-'
                          ? AppColors.successGreen
                          : context.nekoTextSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QueueTaskCard extends StatelessWidget {
  const QueueTaskCard({
    super.key,
    required this.task,
    required this.onDetail,
    this.onCall,
  });

  final MobileTaskItem task;
  final VoidCallback onDetail;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: context.nekoCardDecor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(status: task.status),
                const SizedBox(width: 8),
                Text(
                  task.bagCode ?? task.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.nekoTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.more_vert, color: context.nekoTextSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.nekoInputFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.location_on_outlined,
                      color: context.nekoTextSecondary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.recipientName ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.nekoTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.recipientAddress ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.nekoTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onDetail,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.nekoInputFill,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                        border: Border.all(color: context.nekoDivider),
                      ),
                      child: Center(
                        child: Text(
                          'View Details',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.nekoTextPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (onCall != null) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onCall,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.nekoInputFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.nekoDivider),
                      ),
                      child: Icon(Icons.phone_outlined,
                          color: context.nekoTextPrimary, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
