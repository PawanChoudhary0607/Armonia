// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';

abstract final class AppTheme {
  static ThemeData dark(Color accent) => _build(
        accent: accent,
        brightness: Brightness.dark,
        bgBase: AppColors.darkBgBase,
        bgSurface: AppColors.darkBgSurface,
        bgElevated: AppColors.darkBgElevated,
        bgOverlay: AppColors.darkBgOverlay,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        textTertiary: AppColors.darkTextTertiary,
        borderSubtle: AppColors.darkBorderSubtle,
        borderMedium: AppColors.darkBorderMedium,
      );

  static ThemeData light(Color accent) => _build(
        accent: accent,
        brightness: Brightness.light,
        bgBase: AppColors.lightBgBase,
        bgSurface: AppColors.lightBgSurface,
        bgElevated: AppColors.lightBgElevated,
        bgOverlay: AppColors.lightBgOverlay,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        textTertiary: AppColors.lightTextTertiary,
        borderSubtle: AppColors.lightBorderSubtle,
        borderMedium: AppColors.lightBorderMedium,
      );

  static ThemeData _build({
    required Color accent,
    required Brightness brightness,
    required Color bgBase,
    required Color bgSurface,
    required Color bgElevated,
    required Color bgOverlay,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color borderSubtle,
    required Color borderMedium,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final Color accentOnBg = AppColors.contrastingTextColor(accent);
    final Color secondary = AppColors.secondaryAccent(accent);

    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: accentOnBg,
      primaryContainer: AppColors.fillColor(accent),
      onPrimaryContainer: accent,
      secondary: secondary,
      onSecondary: AppColors.contrastingTextColor(secondary),
      secondaryContainer: AppColors.fillColor(secondary),
      onSecondaryContainer: secondary,
      error: AppColors.danger,
      onError: Colors.white,
      surface: bgSurface,
      onSurface: textPrimary,
      surfaceContainerHighest: bgElevated,
      outline: borderMedium,
      outlineVariant: borderSubtle,
      scrim: Colors.black54,
      inverseSurface:
          isDark ? AppColors.lightBgSurface : AppColors.darkBgSurface,
      onInverseSurface: isDark
          ? AppColors.lightTextPrimary
          : AppColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgBase,
      canvasColor: bgBase,
      cardColor: bgSurface,
      textTheme: _buildTextTheme(textPrimary, textSecondary, textTertiary),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
        titleTextStyle: AppTypography.titleLg.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
        actionsIconTheme: IconThemeData(color: textPrimary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: accentOnBg,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTypography.titleMd,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: borderMedium),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTypography.titleMd,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTypography.titleSm,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.all(10),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        hintStyle: AppTypography.bodyLg.copyWith(color: textTertiary),
        labelStyle: AppTypography.bodyLg.copyWith(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderMedium),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: bgElevated,
        thumbColor: Colors.white,
        overlayColor: AppColors.glowColor(accent),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return bgElevated;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return borderSubtle;
        }),
      ),

      cardTheme: CardThemeData(
        color: bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bgSurface,
        modalBackgroundColor: bgSurface,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: textTertiary,
        dragHandleSize: const Size(40, 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTypography.titleLg.copyWith(color: textPrimary),
        contentTextStyle:
            AppTypography.bodyMd.copyWith(color: textSecondary),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgOverlay,
        contentTextStyle: AppTypography.bodyMd.copyWith(color: textPrimary),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        titleTextStyle:
            AppTypography.titleMd.copyWith(color: textPrimary),
        subtitleTextStyle:
            AppTypography.bodyMd.copyWith(color: textSecondary),
        iconColor: textSecondary,
        minLeadingWidth: 0,
        minVerticalPadding: 8,
      ),

      dividerTheme: DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 0,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: bgElevated,
        labelStyle: AppTypography.label.copyWith(color: textSecondary),
        side: BorderSide(color: borderSubtle),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 0,
        selectedColor: AppColors.fillColor(accent),
        secondarySelectedColor: AppColors.fillColor(accent),
        checkmarkColor: accent,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: bgElevated,
        circularTrackColor: bgElevated,
        linearMinHeight: 2,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: textSecondary,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTypography.titleSm,
        unselectedLabelStyle: AppTypography.titleSm,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: AppColors.fillColor(accent),
    );
  }

  static TextTheme _buildTextTheme(
    Color primary,
    Color secondary,
    Color tertiary,
  ) {
    return TextTheme(
      displayLarge: AppTypography.displayXl.copyWith(color: primary),
      displayMedium: AppTypography.displayLg.copyWith(color: primary),
      displaySmall: AppTypography.displayMd.copyWith(color: primary),
      headlineLarge: AppTypography.displaySm.copyWith(color: primary),
      headlineMedium: AppTypography.titleLg.copyWith(color: primary),
      headlineSmall: AppTypography.titleMd.copyWith(color: primary),
      titleLarge: AppTypography.titleLg.copyWith(color: primary),
      titleMedium: AppTypography.titleMd.copyWith(color: primary),
      titleSmall: AppTypography.titleSm.copyWith(color: primary),
      bodyLarge: AppTypography.bodyLg.copyWith(color: primary),
      bodyMedium: AppTypography.bodyMd.copyWith(color: secondary),
      bodySmall: AppTypography.bodySm.copyWith(color: secondary),
      labelLarge: AppTypography.label.copyWith(color: secondary),
      labelMedium: AppTypography.caption.copyWith(color: secondary),
      labelSmall: AppTypography.caption.copyWith(color: tertiary),
    );
  }
}
