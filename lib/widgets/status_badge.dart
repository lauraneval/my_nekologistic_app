import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status, context);
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

  static _BadgeConfig _configFor(String status, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (status.toUpperCase()) {
      'DELIVERED' || 'COMPLETED' || 'DONE' => _BadgeConfig(
          label: 'DELIVERED',
          bg: isDark ? const Color(0xFF064E3B) : AppColors.deliveredBg,
          text: isDark ? const Color(0xFF6EE7B7) : AppColors.deliveredText,
        ),
      'OUT_FOR_DELIVERY' || 'ACTIVE' || 'IN_PROGRESS' => _BadgeConfig(
          label: 'OUT FOR DELIVERY',
          bg: isDark ? const Color(0xFF431407) : AppColors.outForDeliveryBg,
          text: isDark ? const Color(0xFFFB923C) : AppColors.outForDeliveryText,
        ),
      'IN_TRANSIT' || 'TRANSIT' => _BadgeConfig(
          label: 'IN TRANSIT',
          bg: isDark ? const Color(0xFF451A03) : AppColors.inTransitBg,
          text: isDark ? const Color(0xFFFBBF24) : AppColors.inTransitText,
        ),
      'QUEUED' || 'PENDING' || 'WAITING' => _BadgeConfig(
          label: 'QUEUED',
          bg: isDark ? const Color(0xFF374151) : AppColors.queueBg,
          text: isDark ? const Color(0xFF9CA3AF) : AppColors.queueText,
        ),
      _ => _BadgeConfig(
          label: status.toUpperCase(),
          bg: isDark ? const Color(0xFF374151) : AppColors.queueBg,
          text: isDark ? const Color(0xFF9CA3AF) : AppColors.queueText,
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
