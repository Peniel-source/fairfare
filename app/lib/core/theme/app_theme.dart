// Light and dark themes built from the same terracotta seed (roadmap 3.1).
//
// Look: cream screens, flat tan cards separated by color (no shadow), pill
// shaped buttons and chips, and 48 dp minimum tap targets everywhere.
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({bool useGoogleFonts = true}) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.terracotta,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          secondary: AppColors.orangeText,
          onSecondary: AppColors.white,
          tertiary: AppColors.orangeText,
          surface: AppColors.cream,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.mutedText,
          surfaceContainerLowest: AppColors.white,
          surfaceContainerLow: AppColors.tan,
          surfaceContainer: AppColors.tan,
          surfaceContainerHigh: AppColors.tan,
          surfaceContainerHighest: AppColors.tan,
          outline: AppColors.muted,
          outlineVariant: AppColors.tan,
          error: AppColors.error,
          onError: AppColors.white,
        );
    return _build(
      scheme,
      palette: const AppPalette(
        priceText: AppColors.orangeText,
        mutedText: AppColors.mutedText,
        accent: AppColors.orange,
      ),
      useGoogleFonts: useGoogleFonts,
    );
  }

  static ThemeData dark({bool useGoogleFonts = true}) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.terracotta,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.darkOrangeText,
          onPrimary: AppColors.darkBackground,
          surface: AppColors.darkBackground,
          onSurface: AppColors.darkText,
          onSurfaceVariant: AppColors.darkMutedText,
          surfaceContainerLow: AppColors.darkCard,
          surfaceContainer: AppColors.darkCard,
          surfaceContainerHigh: AppColors.darkCard,
          surfaceContainerHighest: AppColors.darkCard,
        );
    return _build(
      scheme,
      palette: const AppPalette(
        priceText: AppColors.darkOrangeText,
        mutedText: AppColors.darkMutedText,
        accent: AppColors.orange,
      ),
      useGoogleFonts: useGoogleFonts,
    );
  }

  static ThemeData _build(
    ColorScheme scheme, {
    required AppPalette palette,
    required bool useGoogleFonts,
  }) {
    final text = AppTypography.textTheme(
      ink: scheme.onSurface,
      mutedText: palette.mutedText,
      useGoogleFonts: useGoogleFonts,
    );
    const pill = StadiumBorder();
    const minButton = Size(AppSpacing.minTapTarget, AppSpacing.minTapTarget);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: pill,
          minimumSize: minButton,
          padding: buttonPadding,
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: pill,
          elevation: 0,
          minimumSize: minButton,
          padding: buttonPadding,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: pill,
          minimumSize: minButton,
          padding: buttonPadding,
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: pill,
          minimumSize: minButton,
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: minButton),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: minButton,
          shape: pill,
          textStyle: text.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainer,
        // A light tint keeps ink text readable on selected chips too.
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        labelStyle: text.labelLarge,
        checkmarkColor: scheme.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: palette.mutedText),
        hintStyle: text.bodyMedium?.copyWith(color: palette.mutedText),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : palette.mutedText,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : palette.mutedText,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.sheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.fieldRadius),
        backgroundColor: scheme.onSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.surface),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: AppSpacing.lg,
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: AppSpacing.sm,
        iconColor: scheme.primary,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
      ),
    );
  }
}
