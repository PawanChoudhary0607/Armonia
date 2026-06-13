// lib/core/theme/app_typography.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens for Armonia.
///
/// Fonts are loaded via the `google_fonts` package at runtime, so no local
/// font asset files are required in `assets/fonts/`. Each token below is a
/// getter (not `const`) because [GoogleFonts] text styles are computed.
class AppTypography {
  AppTypography._();

  static const String fontDisplay = 'Space Grotesk';
  static const String fontBody = 'Inter';
  static const String fontMono = 'JetBrains Mono';

  // Display — Space Grotesk
  static TextStyle get displayXl => GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -1.0,
      );

  static TextStyle get displayLg => GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.8,
      );

  static TextStyle get displayMd => GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get displaySm => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.5,
      );

  // Titles — Space Grotesk
  static TextStyle get titleLg => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
      );

  static TextStyle get titleMd => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.2,
      );

  static TextStyle get titleSm => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0,
      );

  // Body — Inter
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
      );

  // Caption & label — Inter
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.0,
        letterSpacing: 1.0,
      );

  // Monospace — JetBrains Mono
  static TextStyle get monoLg => GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.0,
        letterSpacing: 0,
      );

  static TextStyle get monoSm => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.0,
        letterSpacing: 0,
      );
}
