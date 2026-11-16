// Flat, rounded card (D1). Cards are separated from the cream background by
// color, not by shadow (roadmap 3.3).
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Makes the whole card tappable, with an ink ripple clipped to its shape.
  final VoidCallback? onTap;

  /// Overrides the theme's card color, for a highlighted card.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
