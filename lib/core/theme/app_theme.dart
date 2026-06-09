import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const Color primaryBlue = Color(0xFF1A3CA8);
  static const Color activeOrange = Color(0xFFF97316);
  static const Color background = Color(0xFFF0F2F8);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color deliveredBg = Color(0xFFD1FAE5);
  static const Color deliveredText = Color(0xFF065F46);
  static const Color inTransitBg = Color(0xFFFEF3C7);
  static const Color inTransitText = Color(0xFF92400E);
  static const Color outForDeliveryBg = Color(0xFFFFF7ED);
  static const Color outForDeliveryText = Color(0xFFC2410C);
  static const Color queueBg = Color(0xFFF3F4F6);
  static const Color queueText = Color(0xFF374151);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
}

abstract class AppRadius {
  static const double card = 16.0;
  static const double button = 24.0;
  static const double badge = 12.0;
}

BoxDecoration nekoCardDecoration({bool hasShadow = true}) => BoxDecoration(
  color: AppColors.cardBg,
  borderRadius: BorderRadius.circular(AppRadius.card),
  boxShadow: hasShadow
      ? const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ]
      : null,
);

abstract class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardBg,
      dividerColor: AppColors.divider,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
      cardColor: const Color(0xFF1F2937),
      dividerColor: const Color(0xFF374151),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

extension NekoThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get nekoBg => isDark ? const Color(0xFF111827) : AppColors.background;
  Color get nekoCardBg => isDark ? const Color(0xFF1F2937) : AppColors.cardBg;
  Color get nekoTextPrimary => isDark ? const Color(0xFFF9FAFB) : AppColors.textPrimary;
  Color get nekoTextSecondary => isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary;
  Color get nekoDivider => isDark ? const Color(0xFF374151) : AppColors.divider;
  Color get nekoInputFill => isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

  BoxDecoration nekoCardDecor({bool hasShadow = true}) => BoxDecoration(
    color: nekoCardBg,
    borderRadius: BorderRadius.circular(AppRadius.card),
    boxShadow: hasShadow && !isDark
        ? const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))]
        : null,
  );
}
