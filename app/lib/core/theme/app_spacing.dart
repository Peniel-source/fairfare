// Spacing, radii and sizes (roadmap section 3.3). Widgets use these instead
// of raw numbers so the whole app keeps one rhythm.
import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  // 4 point scale.
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Side padding of every screen.
  static const EdgeInsets screen = EdgeInsets.all(lg);

  /// Inner padding of a card.
  static const EdgeInsets card = EdgeInsets.all(lg);

  /// Widest a content column grows on tablets and in landscape, so cards
  /// stay readable instead of stretching edge to edge.
  static const double maxContentWidth = 600;

  /// Minimum tap target (Material and WCAG guidance): 48 by 48 dp.
  static const double minTapTarget = 48;
}

class AppRadii {
  AppRadii._();

  /// Cards and hero images: large, 20 to 24 px in the roadmap.
  static const double card = 20;

  /// Bottom sheets and dialogs.
  static const double sheet = 24;

  /// Text fields.
  static const double field = 14;

  /// Buttons, tags and chips are fully pill shaped.
  static const double pill = 999;

  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius fieldRadius = BorderRadius.all(
    Radius.circular(field),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
