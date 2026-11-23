// Profile (E4): name with edit, trust score and streak, badges, leaderboard.
// Opened from the avatar in the home app bar; Settings opens from here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../domain/entities/passenger.dart';
import 'avatar_picker_sheet.dart';
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
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ProfileHeader(passenger: passenger),
            const SizedBox(height: AppSpacing.md),
            TrustScoreCard(
              trustScore: passenger.trustScore,
              streak: passenger.streak,
            ),
            const SizedBox(height: AppSpacing.md),
            BadgeGrid(earnedIds: passenger.badges),
            const SizedBox(height: AppSpacing.md),
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

  Future<void> _chooseAvatar(BuildContext context) async {
    final saved = await showAvatarPicker(
      context,
      currentAvatar: passenger.avatar,
      name: passenger.displayName,
    );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Avatar updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Choose your avatar',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _chooseAvatar(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  avatar: passenger.avatar,
                  name: passenger.displayName,
                  radius: 32,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: scheme.primary,
                    child: Icon(Icons.edit, size: 14, color: scheme.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
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
              if (passenger.avatar == null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => _chooseAvatar(context),
                    child: const Text('Choose your avatar'),
                  ),
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
