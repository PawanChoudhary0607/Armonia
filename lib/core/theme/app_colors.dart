// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark theme backgrounds
  static const Color darkBgBase = Color(0xFF0A0A0A);
  static const Color darkBgSurface = Color(0xFF141414);
  static const Color darkBgElevated = Color(0xFF1C1C1C);
  static const Color darkBgOverlay = Color(0xFF252525);
  static const Color darkGlass = Color(0x0DFFFFFF);
  static const Color darkGlassHeavy = Color(0x17FFFFFF);

  // Dark theme text
  static const Color darkTextPrimary = Color(0xFFF0F0F0);
  static const Color darkTextSecondary = Color(0xFF888888);
  static const Color darkTextTertiary = Color(0xFF555555);
  static const Color darkTextInverted = Color(0xFF0A0A0A);

  // Dark theme borders
  static const Color darkBorderSubtle = Color(0x0FFFFFFF);
  static const Color darkBorderMedium = Color(0x1AFFFFFF);
  static const Color darkBorderStrong = Color(0x2EFFFFFF);

  // Light theme backgrounds
  static const Color lightBgBase = Color(0xFFF5F5F5);
  static const Color lightBgSurface = Color(0xFFFFFFFF);
  static const Color lightBgElevated = Color(0xFFEBEBEB);
  static const Color lightBgOverlay = Color(0xFFE0E0E0);
  static const Color lightGlass = Color(0x0D000000);
  static const Color lightGlassHeavy = Color(0x17000000);

  // Light theme text
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextTertiary = Color(0xFF999999);
  static const Color lightTextInverted = Color(0xFFFFFFFF);

  // Light theme borders
  static const Color lightBorderSubtle = Color(0x12000000);
  static const Color lightBorderMedium = Color(0x1A000000);
  static const Color lightBorderStrong = Color(0x2E000000);

  // Semantic
  static const Color success = Color(0xFF3DDC84);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFFF453A);
  static const Color info = Color(0xFF64B5F6);
  static const Color liked = Color(0xFFFF453A);

  // Accent presets
  static const Color accentIndigo = Color(0xFF6C63FF);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentSlate = Color(0xFF94A3B8);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentCoral = Color(0xFFFF6B6B);

  static const List<Color> accentPresets = [
    accentIndigo,
    accentAmber,
    accentEmerald,
    accentRose,
    accentCyan,
    accentSlate,
    accentViolet,
    accentCoral,
  ];

  static const List<String> accentPresetNames = [
    'Indigo',
    'Amber',
    'Emerald',
    'Rose',
    'Cyan',
    'Slate',
    'Violet',
    'Coral',
  ];

  // Derived accent utilities
  static Color accentWithOpacity(Color accent, double opacity) =>
      accent.withValues(alpha: opacity);

  static Color glowColor(Color accent) => accent.withValues(alpha: 0.25);

  static Color fillColor(Color accent) => accent.withValues(alpha: 0.20);

  static Color secondaryAccent(Color accent) {
    final HSLColor hsl = HSLColor.fromColor(accent);
    final double newHue = (hsl.hue + 40.0) % 360.0;
    final double newLightness = (hsl.lightness - 0.10).clamp(0.0, 1.0);
    return hsl.withHue(newHue).withLightness(newLightness).toColor();
  }

  static Color contrastingTextColor(Color backgroundColor) {
    final double luminance = backgroundColor.computeLuminance();
    return luminance > 0.35 ? Colors.black : Colors.white;
  }
}
