// Trust score (0 to 100) and the daily streak.
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';

class TrustScoreCard extends StatelessWidget {
  const TrustScoreCard({
    super.key,
    required this.trustScore,
    required this.streak,
  });

  final int trustScore;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final score = trustScore.clamp(
      AppConstants.minTrustScore,
      AppConstants.maxTrustScore,
    );
    final isNew = score == 0 && streak == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Trust score $score out of 100',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trust score', style: text.labelLarge),
                        Text('$score', style: text.displaySmall),
                        Text('out of 100', style: text.bodySmall),
                      ],
                    ),
                  ),
                ),
                Semantics(
                  label: 'Streak $streak days',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: streak > 0
                            ? scheme.tertiary
                            : scheme.onSurfaceVariant,
                      ),
                      Text('$streak', style: text.titleLarge),
                      Text(
                        streak == 1 ? 'day streak' : 'days streak',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(value: score / AppConstants.maxTrustScore),
            const SizedBox(height: AppSpacing.md),
            Text(
              isNew
                  ? 'Welcome! Report what you paid after a ride. Each verified '
                        'report adds ${AppConstants.trustVerifiedBonus} points.'
                  : 'Verified reports add ${AppConstants.trustVerifiedBonus} '
                        'points. Rejected reports remove '
                        '${AppConstants.trustRejectedPenalty}.',
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
