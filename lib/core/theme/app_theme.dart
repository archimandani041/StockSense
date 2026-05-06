import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF3B36F5);
  static const Color primaryLight = Color(0xFF6C67F7);
  static const Color primaryDark = Color(0xFF2B27C4);
  static const Color cyan = Color(0xFF4CC9F0);
  static const Color cyanLight = Color(0xFF7DD8F5);

  // Semantic Colors
  static const Color emerald = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color critical = Color(0xFFEF4444);
  static const Color criticalLight = Color(0xFFFEE2E2);

  // Backgrounds
  static const Color background = Color(0xFFF5F7FB);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF0F2F8);
  static const Color borderLight = Color(0xFFE8ECF5);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B36F5), Color(0xFF4CC9F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF2B27C4), Color(0xFF3B36F5), Color(0xFF4CC9F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient criticalGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Status colors
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return emerald;
      case 'low':
        return warning;
      case 'critical':
        return critical;
      default:
        return textSecondary;
    }
  }

  static LinearGradient progressGradient(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return emeraldGradient;
      case 'low':
        return warningGradient;
      case 'critical':
        return criticalGradient;
      default:
        return primaryGradient;
    }
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.cyan,
        surface: AppColors.cardWhite,
        onPrimary: AppColors.textWhite,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        color: AppColors.cardWhite,
      ),
    );
  }
}

// Card Decoration Helpers
BoxDecoration glassCardDecoration({
  double radius = 20,
  Color? borderColor,
  List<Color>? gradientColors,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: AppColors.cardWhite,
    border: Border.all(
      color: borderColor ?? AppColors.borderLight,
      width: 1.2,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.9),
        blurRadius: 1,
        offset: const Offset(0, -1),
      ),
    ],
  );
}

BoxDecoration primaryCardDecoration({double radius = 20}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: AppColors.primaryGradient,
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.35),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
