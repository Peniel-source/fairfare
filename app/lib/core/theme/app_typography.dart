// Type scale (roadmap section 3.2): Fraunces for headlines, Inter for
// everything else, both through google_fonts.
//
// Tests pass `useGoogleFonts: false` so they never try to download a font.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  /// Builds the app's TextTheme with [ink] as the main text color and
  /// [mutedText] for small supporting styles.
  static TextTheme textTheme({
    required Color ink,
    required Color mutedText,
    bool useGoogleFonts = true,
  }) {
    TextStyle serif(double size, {FontWeight weight = FontWeight.w600}) {
      final style = TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: ink,
        height: 1.2,
      );
      return useGoogleFonts ? GoogleFonts.fraunces(textStyle: style) : style;
    }

    TextStyle sans(
      double size, {
      FontWeight weight = FontWeight.w400,
      Color? color,
      double? letterSpacing,
      double height = 1.4,
    }) {
      final style = TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
        letterSpacing: letterSpacing,
        height: height,
      );
      return useGoogleFonts ? GoogleFonts.inter(textStyle: style) : style;
    }

    return TextTheme(
      // Display: hero headline on Landing, 30 to 34 sp.
      displayLarge: serif(34),
      displayMedium: serif(32),
      displaySmall: serif(30),
      // Headline: screen titles, 22 to 24 sp.
      headlineLarge: serif(24),
      headlineMedium: serif(22),
      headlineSmall: serif(20),
      // Title: card titles and corridor names, Inter SemiBold 16 sp.
      titleLarge: sans(18, weight: FontWeight.w600, height: 1.3),
      titleMedium: sans(16, weight: FontWeight.w600, height: 1.3),
      titleSmall: sans(14, weight: FontWeight.w600, height: 1.3),
      // Body: paragraphs and form labels, Inter Regular 14 sp.
      bodyLarge: sans(16),
      bodyMedium: sans(14),
      bodySmall: sans(12, color: mutedText),
      // Labels: buttons, chips and the uppercase eyebrow (11 sp, +1.2).
      labelLarge: sans(14, weight: FontWeight.w600, height: 1.2),
      labelMedium: sans(12, weight: FontWeight.w600, height: 1.2),
      labelSmall: sans(
        11,
        weight: FontWeight.w600,
        color: mutedText,
        letterSpacing: 1.2,
        height: 1.2,
      ),
    );
  }

  /// Large accent style for prices and point balances (roadmap: prices get
  /// their own larger, accent colored style, not just bold body text).
  static TextStyle price(BuildContext context, {double size = 28}) {
    final theme = Theme.of(context);
    final base = theme.textTheme.headlineMedium ?? const TextStyle();
    return base.copyWith(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color:
          theme.extension<AppPalette>()?.priceText ?? theme.colorScheme.primary,
    );
  }

  /// Uppercase section tag ("eyebrow"): call `.toUpperCase()` on the text.
  static TextStyle eyebrow(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
}
