//this builds the price range bar on a corridor card. low to high with a dot for the median
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class GradientRangeBar extends StatelessWidget {
  const GradientRangeBar({
    super.key,
    required this.low,
    required this.median,
    required this.high,
  });

  final int low;
  final int median;
  final int high;

  //dot position 0 is the left end 1 is the right end
  double get dotPosition {
    if (high <= low) return 0.5;
    final position = (median - low) / (high - low);
    return position.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).extension<AppPalette>()!.accent;

    return Semantics(
      label: 'Typical price from $low to $high, fair price $median',
      excludeSemantics: true,
      child: SizedBox(
        height: 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            //the bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: AppRadii.pillRadius,
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.3), accent],
                ),
              ),
            ),
            //the dot for  median
            Align(
              alignment: Alignment(dotPosition * 2 - 1, 0),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cream, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}