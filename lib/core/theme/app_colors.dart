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

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'OpenSans';
  static String? get displayFontFamily => GoogleFonts.teko().fontFamily;
}
