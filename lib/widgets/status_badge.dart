import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        config.label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: config.text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static _BadgeConfig _configFor(String status) {
    return switch (status.toUpperCase()) {
      'DELIVERED' || 'COMPLETED' || 'DONE' => _BadgeConfig(
          label: 'DELIVERED',
          bg: AppColors.deliveredBg,
          text: AppColors.deliveredText,
        ),
      'OUT_FOR_DELIVERY' || 'ACTIVE' || 'IN_PROGRESS' => _BadgeConfig(
          label: 'SEDANG DIANTAR',
          bg: AppColors.outForDeliveryBg,
          text: AppColors.outForDeliveryText,
        ),
      'IN_TRANSIT' || 'TRANSIT' => _BadgeConfig(
          label: 'IN TRANSIT',
          bg: AppColors.inTransitBg,
          text: AppColors.inTransitText,
        ),
      'QUEUED' || 'PENDING' || 'WAITING' => _BadgeConfig(
          label: 'ANTRIAN',
          bg: AppColors.queueBg,
          text: AppColors.queueText,
        ),
      _ => _BadgeConfig(
          label: status.toUpperCase(),
          bg: AppColors.queueBg,
          text: AppColors.queueText,
        ),
    };
  }
}

class _BadgeConfig {
  const _BadgeConfig({required this.label, required this.bg, required this.text});
  final String label;
  final Color bg;
  final Color text;
}
