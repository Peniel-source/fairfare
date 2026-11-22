// Settings screen (D3): theme mode, default time of day, replay welcome, and
// the Account section with Logout.
//
// Every change goes through settingsProvider, which saves it to
// shared_preferences, so it is still applied after an app restart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_label_row.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../report/domain/entities/report_enums.dart';
import '../domain/entities/app_settings.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              const _SectionTitle('Appearance'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ThemeModeSelector(
                      value: settings.themeMode,
                      onChanged: controller.setThemeMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Reporting'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default time of day',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pre-selected when you report a fare.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _TimeSegmentSelector(
                      value: settings.defaultTimeSegment,
                      onChanged: controller.setDefaultTimeSegment,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Help'),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: IconLabelRow(
                  icon: Icons.replay,
                  label: 'Replay welcome',
                  description: 'Show the welcome screen again next time.',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await controller.setOnboardingSeen(false);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'The welcome screen will show the next time you '
                          'open FairFare signed out.',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Account'),
              const _AccountCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.value, required this.onChanged});

  final ThemeModeOption value;
  final ValueChanged<ThemeModeOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeModeOption>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: ThemeModeOption.system,
            icon: Icon(Icons.brightness_auto_outlined),
            label: Text('System'),
          ),
          ButtonSegment(
            value: ThemeModeOption.light,
            icon: Icon(Icons.light_mode_outlined),
            label: Text('Light'),
          ),
          ButtonSegment(
            value: ThemeModeOption.dark,
            icon: Icon(Icons.dark_mode_outlined),
            label: Text('Dark'),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _TimeSegmentSelector extends StatelessWidget {
  const _TimeSegmentSelector({required this.value, required this.onChanged});

  final TimeSegment value;
  final ValueChanged<TimeSegment> onChanged;

  static String label(TimeSegment segment) => switch (segment) {
    TimeSegment.morning => 'Morning',
    TimeSegment.midday => 'Midday',
    TimeSegment.evening => 'Evening',
    TimeSegment.lateNight => 'Late night',
  };

  @override
  Widget build(BuildContext context) {
    // A Wrap instead of a segmented row: four options never overflow on a
    // small phone, they move to a second line.
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final segment in TimeSegment.values)
          ChoiceChip(
            label: Text(label(segment)),
            selected: segment == value,
            onSelected: (_) => onChanged(segment),
          ),
      ],
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconLabelRow(
            icon: Icons.mail_outline,
            label: 'Email',
            description: user?.email ?? 'Not signed in',
          ),
          IconLabelRow(
            icon: user?.emailVerified == true
                ? Icons.verified_outlined
                : Icons.mark_email_unread_outlined,
            label: 'Email status',
            description: user == null
                ? '—'
                : user.emailVerified
                ? 'Verified'
                : 'Not verified yet',
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Log out',
            icon: Icons.logout,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: user == null ? null : () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign in again at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Signs out of Firebase, and of Google when it was used (D2). The router
    // listens to the auth state and sends the passenger to Landing. Providers
    // holding a passenger's data (wallet, pass, profile, saved routes) watch
    // the signed-in uid, so they rebuild empty and the next user starts clean.
    final controller = ref.read(authControllerProvider.notifier);
    final signedOut = await controller.signOut();
    if (signedOut || !context.mounted) return;
    final error = ref.read(authControllerProvider).error;
    controller.clearError();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Could not log out. Please try again'
              : authErrorMessage(error),
        ),
      ),
    );
  }
}
