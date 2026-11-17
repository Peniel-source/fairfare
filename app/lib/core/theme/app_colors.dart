// FairFare palette (roadmap section 3.1), with the contrast fixes recorded in
// docs/contrast_check.md.
//
// The mockups use one warm hue family: cream, tan, terracotta and orange.
// State is shown through saturation and position, not by switching hues.
//
// Widgets never hard code a color. They read Theme.of(context).colorScheme,
// or these constants when the scheme has no matching role.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ---- Brand palette, as in the roadmap --------------------------------

  /// Screen background (cream).
  static const Color cream = Color(0xFFF7F1E6);

  /// Cards, chips and panels on cream (tan).
  static const Color tan = Color(0xFFEEE1CD);

  /// Seed for the Material 3 scheme. Too light for white button text
  /// (4.16 to 1), so the primary role uses [primary] instead.
  static const Color terracotta = Color(0xFFC1622C);

  /// Decorative accent only: gradient bars, badge fills, icons.
  /// Too light for text on cream (2.83 to 1). Use [orangeText] for text.
  static const Color orange = Color(0xFFD97706);

  /// Headlines and primary text.
  static const Color ink = Color(0xFF2A2118);

  /// Original muted tone. Fails 4.5 to 1 as text (3.68 on cream), so it is
  /// kept for borders and dividers only. Use [mutedText] for captions.
  static const Color muted = Color(0xFF8B7A67);

  // ---- Contrast corrections (docs/contrast_check.md) -------------------

  /// Secondary and caption text. 5.41 to 1 on cream, 4.71 on tan.
  static const Color mutedText = Color(0xFF6E6051);

  /// Orange for price figures and tags. 5.33 to 1 on cream, 4.65 on tan.
  static const Color orangeText = Color(0xFF965204);

  /// Deeper terracotta for the primary role: filled buttons behind white
  /// text (6.02 to 1), and links, active icons and text on cream (5.36) and
  /// tan (4.67).
  static const Color primary = Color(0xFF9A4E23);

  // ---- Neutrals --------------------------------------------------------

  static const Color white = Color(0xFFFFFFFF);

  /// Error red tuned to the warm palette. 5.81 to 1 on cream, 5.07 on tan.
  static const Color error = Color(0xFFB3261E);

  // ---- Dark scheme surfaces (no designed dark mode in Figma) ------------

  static const Color darkBackground = Color(0xFF1C1712);
  static const Color darkCard = Color(0xFF2A231C);
  static const Color darkText = Color(0xFFF3EADC);
  static const Color darkMutedText = Color(0xFFC9B9A5);

  /// Primary and price text in dark mode. 8.79 to 1 on [darkBackground].
  static const Color darkOrangeText = Color(0xFFF2A65A);
}

/// Colors the ColorScheme has no role for, kept on the theme so they change
/// with light and dark mode.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.priceText,
    required this.mutedText,
    required this.accent,
  });

  /// Price figures, point balances and tag text (passes 4.5 to 1).
  final Color priceText;

  /// Captions and secondary text (passes 4.5 to 1).
  final Color mutedText;

  /// Decorative orange: icons, gradient bars, badge fills. Not for text.
  final Color accent;

  @override
  AppPalette copyWith({Color? priceText, Color? mutedText, Color? accent}) {
    return AppPalette(
      priceText: priceText ?? this.priceText,
      mutedText: mutedText ?? this.mutedText,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      priceText: Color.lerp(priceText, other.priceText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}
