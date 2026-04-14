import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFFC41E3A); // Blood red
  static const Color primaryDark = Color(0xFF8B0000);
  static const Color primaryLight = Color(0xFFE53935);

  // Accent colors
  static const Color accent = Color(0xFFD4AF37); // Gold
  static const Color accentLight = Color(0xFFFFD700);

  // Background colors
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF2D2D2D);
  static const Color card = Color(0xFF252525);
  static const Color cardHover = Color(0xFF333333);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF808080);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Player states
  static const Color healthy = Color(0xFF4CAF50);
  static const Color injured = Color(0xFFFFC107);
  static const Color mng = Color(0xFFFF9800);
  static const Color dead = Color(0xFFE53935);

  // Skill families
  static const Color skillGeneral = Color(0xFF00ACC1);
  static const Color skillAgility = Color(0xFF4CAF50);
  static const Color skillStrength = Color(0xFFE53935);
  static const Color skillPassing = Color(0xFF2196F3);
  static const Color skillMutation = Color(0xFF9C27B0);
  static const Color skillExtraordinary = Color(0xFFD4AF37);

  // League status
  static const Color leagueActive = Color(0xFF4CAF50);
  static const Color leaguePaused = Color(0xFFFFC107);
  static const Color leagueFinished = Color(0xFF9E9E9E);
}

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'OpenSans';
  // Fuente estilo fútbol americano
  static String? get displayFont => GoogleFonts.teko().fontFamily;

  static TextStyle get displayLarge => TextStyle(
        fontFamily: displayFont,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => TextStyle(
        fontFamily: displayFont,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get displaySmall => TextStyle(
        fontFamily: displayFont,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle stat = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle statLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 1,
  );
}
