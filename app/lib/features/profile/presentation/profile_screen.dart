// Profile (E4): name with edit, trust score and streak, badges, leaderboard.
// Opened from the avatar in the home app bar; Settings opens from here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../domain/entities/passenger.dart';
import 'badge_grid.dart';
import 'edit_display_name_dialog.dart';
import 'leaderboard_list.dart';
import 'profile_providers.dart';
import 'trust_score_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: me.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ProfileError(
          message: profileErrorMessage(error),
          onRetry: () => ref.invalidate(meProvider),
        ),
        data: (passenger) => _ProfileContent(passenger: passenger),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.passenger});

  final Passenger passenger;

  @override
  Widget build(BuildContext context) {
    return Center(
      // Readable width on tablets and in landscape.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeader(passenger: passenger),
            const SizedBox(height: 12),
            TrustScoreCard(
              trustScore: passenger.trustScore,
              streak: passenger.streak,
            ),
            const SizedBox(height: 12),
            BadgeGrid(earnedIds: passenger.badges),
            const SizedBox(height: 12),
            LeaderboardList(currentPassengerId: passenger.id),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.passenger});

  final Passenger passenger;

  Future<void> _edit(BuildContext context) async {
    final saved = await showEditDisplayNameDialog(
      context,
      currentName: passenger.displayName,
    );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          child: Text(
            Formatters.initials(passenger.displayName),
            style: text.titleLarge,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                passenger.displayName,
                style: text.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                passenger.email,
                style: text.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Edit display name',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _edit(context),
        ),
      ],
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
