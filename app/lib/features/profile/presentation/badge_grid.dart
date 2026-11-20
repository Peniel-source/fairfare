// Every badge, earned or locked. Locked badges say how to earn them.
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../domain/badges.dart';

class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key, required this.earnedIds});

  final List<String> earnedIds;

  static const _icons = {
    'corridor_pioneer': Icons.flag,
    'week_streak': Icons.calendar_month,
    'ten_verified': Icons.verified,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final earnedCount = Badges.all
        .where((b) => earnedIds.contains(b.id))
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Badges ($earnedCount of ${Badges.all.length})',
              style: text.titleMedium,
            ),
            if (earnedCount == 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'No badges yet. Here is how to earn them.',
                style: text.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            // Wrap instead of a fixed grid, so tiles reflow in landscape.
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final badge in Badges.all)
                  _BadgeTile(
                    badge: badge,
                    icon: _icons[badge.id] ?? Icons.emoji_events,
                    earned: earnedIds.contains(badge.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.icon,
    required this.earned,
  });

  final BadgeInfo badge;
  final IconData icon;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Semantics(
      label:
          '${badge.title}, ${earned ? 'earned' : 'locked. ${badge.howToEarn}'}',
      excludeSemantics: true,
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: earned
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              child: Icon(
                earned ? icon : Icons.lock_outline,
                color: earned
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: text.labelMedium,
            ),
            if (!earned)
              Text(
                badge.howToEarn,
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
