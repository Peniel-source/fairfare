//this creates the card for one corridor. it should show price and confidence
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/gradient_bar.dart';
import '../domain/entities/corridor.dart';
import '../domain/entities/corridor_stats.dart';

class CorridorCard extends StatelessWidget {
  const CorridorCard({
    super.key,
    required this.corridor,
    required this.stats,
    required this.onTap,
  });

  final Corridor corridor;

  //it should return null if no reports yet
  final CorridorStats? stats;
  final VoidCallback onTap;

  //confidence text to display on the card
  String confidenceText(String confidence) {
    if (confidence == 'wellCovered') return 'Well covered';
    if (confidence == 'limited') return 'Limited data';
    return 'few reports';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppPalette>()!;

    return AppCard(
      onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //corridor name
              Text(
                '${corridor.fromArea} to ${corridor.toArea}',
                style: text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (stats == null)
                Text(
                  'No reports yet. Be the first to share a price.',
                  style: text.bodyMedium?.copyWith(color: palette.mutedText),
                )
              else ...[
                //the typical price
                Text(
                  Formatters.price(stats!.median),
                  style: text.titleLarge?.copyWith(color: palette.priceText),
                ),
                const SizedBox(height: AppSpacing.sm),
                GradientRangeBar(
                  low: stats!.low,
                  median: stats!.median,
                  high: stats!.high,
                ),
                const SizedBox(height: AppSpacing.sm),
                //price range in words
                Text(
                  'Usually ${Formatters.priceRange(stats!.low, stats!.high)}',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${stats!.sampleSize} reports · ${confidenceText(stats!.confidence)} · '
                      'updated ${Formatters.relativeTime(stats!.updatedAt)}',
                  style: text.bodySmall?.copyWith(color: palette.mutedText),
                ),
              ],
            ],
          ),
        ),
    );
  }
}