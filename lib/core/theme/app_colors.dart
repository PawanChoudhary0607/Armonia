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
  static const Color accentArmoniaCyan = Color(0xFF22D3EE);
  static const Color accentIndigo = Color(0xFF6C63FF);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentSlate = Color(0xFF94A3B8);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentCoral = Color(0xFFFF6B6B);

  /// Phase 4A — Armonia's signature accent, inspired by the waveform logo.
  /// This is now the default accent for new installs (see
  /// [AppConstants.defaultAccentColorValue]). It is listed first in
  /// [accentPresets] so it reads as the "brand" choice in the picker.
  static const List<Color> accentPresets = [
    accentArmoniaCyan,
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
    'Armonia Cyan',
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

  // ── PHASE 4A — PREMIUM SURFACES ──────────────────────────────────────
  //
  // Subtle, dark-first gradients used to give cards, quick-access tiles,
  // and the Player screen background a sense of depth and "tint" without
  // ever overpowering the near-black base palette.

  /// Diagonal gradient for premium cards — a near-black elevated surface
  /// fading toward a faint tint of [tint]. Used for quick-access tiles,
  /// curated playlist cards, and profile stat cards.
  static LinearGradient premiumCardGradient(Color tint) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        darkBgElevated,
        Color.lerp(darkBgElevated, tint, 0.16) ?? darkBgElevated,
      ],
    );
  }

  /// Full-bleed vertical gradient for the Player screen background —
  /// the near-black base tinted by [accent] at the top, settling back to
  /// pure [darkBgBase] toward the bottom. Combined with a blurred album-art
  /// layer, this produces the "Room" effect without on-device dominant
  /// color extraction.
  static LinearGradient playerBackgroundGradient(Color accent) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(darkBgBase, accent, 0.32) ?? darkBgBase,
        darkBgBase,
        darkBgBase,
      ],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  /// Theme-aware variant of [premiumCardGradient]. Uses the surrounding
  /// theme's elevated surface color so premium cards render correctly in
  /// both dark and light theme instead of always using the dark elevated
  /// surface.
  static LinearGradient premiumCardGradientFor(
    BuildContext context,
    Color tint,
  ) {
    final Color base = context.appColors.bgElevated;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        base,
        Color.lerp(base, tint, 0.16) ?? base,
      ],
    );
  }

  /// Theme-aware variant of [playerBackgroundGradient]. Settles back to the
  /// current theme's base background color instead of always the dark
  /// near-black base.
  static LinearGradient playerBackgroundGradientFor(
    BuildContext context,
    Color accent,
  ) {
    final Color base = context.appColors.bgBase;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(base, accent, 0.32) ?? base,
        base,
        base,
      ],
      stops: const [0.0, 0.55, 1.0],
    );
  }
}

/// ── PHASE 4B — THEME-AWARE SURFACE & TEXT TOKENS ──────────────────────────
///
/// A [ThemeExtension] that exposes the same semantic tokens used throughout
/// the design system (background layers, text colors, borders, glass
/// surfaces) but resolved for whichever brightness is currently active.
///
/// Historically, screens referenced [AppColors.darkBgBase],
/// [AppColors.darkTextPrimary], etc. directly — which looked correct in dark
/// mode but produced unreadable/invisible UI in light mode (e.g. near-white
/// text on a white surface). Screens should now read these values via
/// `context.appColors.xxx`, which automatically resolves to the dark or
/// light token depending on the active [ThemeData].
@immutable
class AppColorsExt extends ThemeExtension<AppColorsExt> {
  const AppColorsExt({
    required this.bgBase,
    required this.bgSurface,
    required this.bgElevated,
    required this.bgOverlay,
    required this.glass,
    required this.glassHeavy,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverted,
    required this.borderSubtle,
    required this.borderMedium,
    required this.borderStrong,
  });

  final Color bgBase;
  final Color bgSurface;
  final Color bgElevated;
  final Color bgOverlay;
  final Color glass;
  final Color glassHeavy;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverted;
  final Color borderSubtle;
  final Color borderMedium;
  final Color borderStrong;

  static const AppColorsExt dark = AppColorsExt(
    bgBase: AppColors.darkBgBase,
    bgSurface: AppColors.darkBgSurface,
    bgElevated: AppColors.darkBgElevated,
    bgOverlay: AppColors.darkBgOverlay,
    glass: AppColors.darkGlass,
    glassHeavy: AppColors.darkGlassHeavy,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    textInverted: AppColors.darkTextInverted,
    borderSubtle: AppColors.darkBorderSubtle,
    borderMedium: AppColors.darkBorderMedium,
    borderStrong: AppColors.darkBorderStrong,
  );

  static const AppColorsExt light = AppColorsExt(
    bgBase: AppColors.lightBgBase,
    bgSurface: AppColors.lightBgSurface,
    bgElevated: AppColors.lightBgElevated,
    bgOverlay: AppColors.lightBgOverlay,
    glass: AppColors.lightGlass,
    glassHeavy: AppColors.lightGlassHeavy,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    textInverted: AppColors.lightTextInverted,
    borderSubtle: AppColors.lightBorderSubtle,
    borderMedium: AppColors.lightBorderMedium,
    borderStrong: AppColors.lightBorderStrong,
  );

  @override
  AppColorsExt copyWith({
    Color? bgBase,
    Color? bgSurface,
    Color? bgElevated,
    Color? bgOverlay,
    Color? glass,
    Color? glassHeavy,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverted,
    Color? borderSubtle,
    Color? borderMedium,
    Color? borderStrong,
  }) {
    return AppColorsExt(
      bgBase: bgBase ?? this.bgBase,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      bgOverlay: bgOverlay ?? this.bgOverlay,
      glass: glass ?? this.glass,
      glassHeavy: glassHeavy ?? this.glassHeavy,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverted: textInverted ?? this.textInverted,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderMedium: borderMedium ?? this.borderMedium,
      borderStrong: borderStrong ?? this.borderStrong,
    );
  }

  @override
  AppColorsExt lerp(ThemeExtension<AppColorsExt>? other, double t) {
    if (other is! AppColorsExt) return this;
    return AppColorsExt(
      bgBase: Color.lerp(bgBase, other.bgBase, t) ?? bgBase,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t) ?? bgSurface,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t) ?? bgElevated,
      bgOverlay: Color.lerp(bgOverlay, other.bgOverlay, t) ?? bgOverlay,
      glass: Color.lerp(glass, other.glass, t) ?? glass,
      glassHeavy: Color.lerp(glassHeavy, other.glassHeavy, t) ?? glassHeavy,
      textPrimary:
          Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary:
          Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      textInverted:
          Color.lerp(textInverted, other.textInverted, t) ?? textInverted,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      borderMedium:
          Color.lerp(borderMedium, other.borderMedium, t) ?? borderMedium,
      borderStrong:
          Color.lerp(borderStrong, other.borderStrong, t) ?? borderStrong,
    );
  }
}

/// Convenience accessor: `context.appColors.bgSurface`, etc.
///
/// Falls back to [AppColorsExt.dark] if the current [ThemeData] does not
/// carry the extension (should not happen once [AppTheme] registers it, but
/// keeps this accessor safe for tests/previews that build bare ThemeData).
extension AppColorsContext on BuildContext {
  AppColorsExt get appColors =>
      Theme.of(this).extension<AppColorsExt>() ?? AppColorsExt.dark;
}
