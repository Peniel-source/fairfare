// Top 10 passengers by trust score, with the current passenger highlighted.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../domain/entities/leaderboard_entry.dart';
import 'profile_providers.dart';

class LeaderboardList extends ConsumerWidget {
  const LeaderboardList({super.key, required this.currentPassengerId});

  final String currentPassengerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final board = ref.watch(leaderboardProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Leaderboard', style: text.titleMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            board.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(profileErrorMessage(error)),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(leaderboardProvider),
                  child: const Text('Retry'),
                ),
              ),
              data: (rows) => rows.isEmpty
                  ? const ListTile(
                      title: Text('No scores yet. Be the first on the board!'),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < rows.length; i++)
                          _LeaderboardRow(
                            rank: i + 1,
                            entry: rows[i],
                            isMe: rows[i].id == currentPassengerId,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ListTile(
      key: ValueKey('leaderboard-${entry.id}'),
      selected: isMe,
      selectedTileColor: scheme.secondaryContainer,
      selectedColor: scheme.onSecondaryContainer,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 32, child: Text('#$rank', style: text.titleSmall)),
          UserAvatar(avatar: entry.avatar, name: entry.displayName, radius: 16),
        ],
      ),
      title: Text(isMe ? '${entry.displayName} (you)' : entry.displayName),
      trailing: Text('${entry.trustScore}', style: text.titleMedium),
    );
  }
}
