import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/icon_label_row.dart';
import '../../../shared/widgets/loading_view.dart';
import 'landing_providers.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fare = ref.watch(landingFareProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'FAIR MOTO FARES · KIGALI',
                    textAlign: TextAlign.center,
                    style: AppTypography.eyebrow(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: ClipRRect(
                      borderRadius: AppRadii.cardRadius,
                      child: Image.asset(
                        'assets/images/welcome_moto.png',
                        width: 128,
                        height: 128,
                        semanticLabel: 'FairFare moto passenger illustration',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Never overpay for a '),
                        TextSpan(
                          text: 'moto',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const TextSpan(text: ' in Kigali again.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Know the fare before you ride. Built from prices shared by passengers.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Fare pulse', style: theme.textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.md),
                        fare.when(
                          loading: () => const LoadingView(
                            message: 'Loading fare preview…',
                          ),
                          error: (_, _) => ErrorView(
                            compact: true,
                            message: 'Could not load the fare preview.',
                            onRetry: () => ref.invalidate(landingFareProvider),
                          ),
                          data: (value) => value == null
                              ? const EmptyView(
                                  compact: true,
                                  title: 'No fares yet',
                                  message: 'Fare ranges will appear here as reports come in.',
                                  icon: Icons.route_outlined,
                                )
                              : _FarePreview(fare: value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppCard(
                    child: Column(
                      children: [
                        IconLabelRow(
                          icon: Icons.search,
                          label: 'Search corridors',
                          description:
                              'Check a fare range before you negotiate.',
                        ),
                        IconLabelRow(
                          icon: Icons.edit_note,
                          label: 'Share your fare',
                          description: 'Report what you paid after a ride.',
                        ),
                        IconLabelRow(
                          icon: Icons.people_outline,
                          label: 'Help other passengers',
                          description:
                              'Make Kigali fares clearer for everyone.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Create account',
                    expand: true,
                    onPressed: () => context.goNamed('register'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Sign in',
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    onPressed: () => context.goNamed('login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FarePreview extends StatelessWidget {
  const _FarePreview({required this.fare});

  final LandingFare fare;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${fare.corridor.fromArea} → ${fare.corridor.toArea}',
          style: text.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          Formatters.priceRange(fare.stats.low, fare.stats.high),
          style: AppTypography.price(context),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${fare.stats.sampleSize} reports · ${fare.stats.confidence}',
          style: text.bodySmall,
        ),
      ],
    );
  }
}
