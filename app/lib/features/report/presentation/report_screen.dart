import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/home_app_bar.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/price_stepper.dart';
import '../../../shared/widgets/segmented_selector.dart';
import '../../corridors/domain/entities/corridor.dart';
import '../../corridors/presentation/corridor_providers.dart';
import '../domain/entities/report_enums.dart';
import '../domain/price_sanity.dart';
import 'report_banners.dart';
import 'report_form_controller.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fill the usual price unless one was typed
    ref.listen(selectedCorridorStatsProvider, (_, next) {
      final stats = next.value;
      if (stats != null && ref.read(reportFormProvider).price == null) {
        ref.read(reportFormProvider.notifier).setPrice(stats.median);
      }
    });

    final areas = ref.watch(reportAreasProvider);

    return Scaffold(
      appBar: const HomeAppBar(),
      body: areas.when(
        loading: () => const LoadingView(message: 'Loading routes…'),
        error: (_, _) => ErrorView(
          message: 'Could not load the routes. Check your connection.',
          onRetry: () => ref.invalidate(popularCorridorsProvider),
        ),
        data: (areas) => _ReportForm(areas: areas),
      ),
    );
  }
}

class _ReportForm extends ConsumerWidget {
  const _ReportForm({required this.areas});

  final List<String> areas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(reportFormProvider);
    final submitted = form.submitted != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            const _Header(),
            const SizedBox(height: AppSpacing.lg),
            const _RecentRoutes(),
            const SizedBox(height: AppSpacing.md),
            _RouteCard(areas: areas),
            const SizedBox(height: AppSpacing.md),
            const _PriceCard(),
            const SizedBox(height: AppSpacing.md),
            const _TimeCard(),
            const SizedBox(height: AppSpacing.md),
            const _WeatherCard(),
            const SizedBox(height: AppSpacing.md),
            const _StatusSection(),
            const _CommunityImpactCard(),
            const SizedBox(height: AppSpacing.md),
            const _PrivacyNote(),
            const SizedBox(height: AppSpacing.lg),
            if (!submitted)
              AppButton(
                label: 'Submit report',
                icon: Icons.send,
                expand: true,
                isLoading: form.isSubmitting,
                onPressed: () => _submit(context, ref),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reportFormProvider.notifier).submit();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(reportErrorMessage(error))),
      );
    }
  }
}

/// Section label
class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.eyebrow(context);
    final accent = Theme.of(context).extension<AppPalette>()?.priceText;
    return Row(
      children: [
        Expanded(child: Text(text.toUpperCase(), style: style)),
        if (trailing != null)
          Text(trailing!.toUpperCase(), style: style.copyWith(color: accent)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 16, color: palette?.accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '15-second report',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: palette?.priceText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Report your ride fare',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Takes 15 seconds · earns pool rewards',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'My reports',
          icon: const Icon(Icons.two_wheeler),
          onPressed: () => context.push('/my-reports'),
        ),
      ],
    );
  }
}

class _RecentRoutes extends ConsumerWidget {
  const _RecentRoutes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(recentRoutesProvider);
    if (routes.isEmpty) return const SizedBox.shrink();
    final notifier = ref.read(reportFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('Quick load recent route', trailing: 'Tap to autofill'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final route in routes)
              ActionChip(
                avatar: const Icon(Icons.history, size: 18),
                label: Text('${route.fromArea} → ${route.toArea}'),
                onPressed: () => notifier.applyRoute(route),
              ),
          ],
        ),
      ],
    );
  }
}

class _RouteCard extends ConsumerWidget {
  const _RouteCard({required this.areas});

  final List<String> areas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(reportFormProvider);
    final corridor = ref.watch(selectedCorridorProvider);
    final notifier = ref.read(reportFormProvider.notifier);
    final error = form.showErrors
        ? routeError(
            pickup: form.pickup,
            dropoff: form.dropoff,
            corridor: corridor,
          )
        : null;
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Corridor segment'),
          const SizedBox(height: AppSpacing.md),
          _AreaField(
            key: ValueKey('pickup-${form.pickup}'),
            badge: 'A',
            label: 'Pickup point',
            areas: areas,
            value: form.pickup,
            onSelected: notifier.setPickup,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Swap pickup and drop-off',
              icon: const Icon(Icons.swap_vert),
              onPressed: notifier.swapRoute,
            ),
          ),
          _AreaField(
            key: ValueKey('dropoff-${form.dropoff}'),
            badge: 'B',
            label: 'Drop-off area',
            areas: areas,
            value: form.dropoff,
            onSelected: notifier.setDropoff,
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Area dropdown with the A or B badge
class _AreaField extends StatelessWidget {
  const _AreaField({
    super.key,
    required this.badge,
    required this.label,
    required this.areas,
    required this.value,
    required this.onSelected,
  });

  final String badge;
  final String label;
  final List<String> areas;
  final String? value;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // White fields on the tan card
    final fieldTheme = theme.copyWith(
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        fillColor: scheme.surfaceContainerLowest,
      ),
    );

    return Theme(
      data: fieldTheme,
      child: DropdownMenu<String>(
        initialSelection: value,
        expandedInsets: EdgeInsets.zero,
        enableFilter: true,
        requestFocusOnTap: true,
        label: Text(label),
        leadingIcon: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: Text(
              badge,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onPrimary,
              ),
            ),
          ),
        ),
        dropdownMenuEntries: [
          for (final area in areas) DropdownMenuEntry(value: area, label: area),
        ],
        onSelected: onSelected,
      ),
    );
  }
}

class _PriceCard extends ConsumerWidget {
  const _PriceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(reportFormProvider);
    final stats = ref.watch(selectedCorridorStatsProvider).value;
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: _Eyebrow('Price paid (meter or cash)')),
              if (stats != null)
                Text(
                  'Usual price: ${stats.median} RWF',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PriceStepper(
            value: form.price,
            onChanged: ref.read(reportFormProvider.notifier).setPrice,
            max: AppConstants.maxReportPrice,
            quickValues: quickPrices(stats),
            errorText: form.showErrors ? priceSanityError(form.price) : null,
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends ConsumerWidget {
  const _TimeCard();

  static const _options = [
    SegmentOption(
      value: TimeSegment.morning,
      label: 'Morning',
      icon: Icons.wb_twilight,
    ),
    SegmentOption(
      value: TimeSegment.midday,
      label: 'Midday',
      icon: Icons.light_mode_outlined,
    ),
    SegmentOption(
      value: TimeSegment.evening,
      label: 'Evening',
      icon: Icons.nights_stay_outlined,
    ),
    SegmentOption(
      value: TimeSegment.lateNight,
      label: 'Late night',
      icon: Icons.bedtime_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(reportFormProvider.select((s) => s.timeSegment));
    final isRush =
        segment == TimeSegment.morning || segment == TimeSegment.evening;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Eyebrow('Time of ride', trailing: isRush ? 'Rush hour' : null),
          const SizedBox(height: AppSpacing.md),
          SegmentedSelector<TimeSegment>(
            options: _options,
            selected: segment,
            onChanged: ref.read(reportFormProvider.notifier).setTimeSegment,
          ),
        ],
      ),
    );
  }
}

class _WeatherCard extends ConsumerWidget {
  const _WeatherCard();

  static const _options = [
    SegmentOption(
      value: Weather.clear,
      label: 'Clear / normal',
      icon: Icons.wb_cloudy_outlined,
    ),
    SegmentOption(
      value: Weather.heavyRain,
      label: 'Heavy rain',
      icon: Icons.thunderstorm_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(reportFormProvider.select((s) => s.weather));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Eyebrow('Weather', trailing: 'Rain widens the range'),
          const SizedBox(height: AppSpacing.md),
          SegmentedSelector<Weather>(
            options: _options,
            selected: weather,
            onChanged: ref.read(reportFormProvider.notifier).setWeather,
          ),
        ],
      ),
    );
  }
}

/// Band preview before submit, live status after
class _StatusSection extends ConsumerWidget {
  const _StatusSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(reportFormProvider);
    final Widget? banner;

    if (form.submitted != null) {
      banner = SubmittedReportBanner(
        report: ref.watch(submittedReportProvider),
        now: ref.watch(minuteClockProvider).value ?? DateTime.now(),
        onReportAnother: ref.read(reportFormProvider.notifier).reset,
        onOpenMyReports: () => context.push('/my-reports'),
      );
    } else if (ref.watch(selectedCorridorProvider) != null &&
        priceSanityError(form.price) == null) {
      banner = BandPreviewBanner(
        stats: ref.watch(selectedCorridorStatsProvider),
        price: form.price!,
        timeSegment: form.timeSegment,
        weather: form.weather,
      );
    } else {
      banner = null;
    }

    if (banner == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: banner,
    );
  }
}

class _CommunityImpactCard extends ConsumerWidget {
  const _CommunityImpactCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Corridor? corridor = ref.watch(selectedCorridorProvider);
    final theme = Theme.of(context);
    final route = corridor == null
        ? 'this route'
        : '${corridor.fromArea} → ${corridor.toArea}';

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.groups_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow(
                  'Community impact',
                  trailing: '+${AppConstants.trustVerifiedBonus} trust score',
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your report sets the fair price for $route for every '
                  'passenger who checks it. Earn '
                  '+${AppConstants.trustVerifiedBonus} trust score and a pool '
                  'reward when another passenger confirms it.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        Icon(Icons.lock_outline, size: 16, color: style?.color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'No phone numbers or plates are recorded. Other passengers never '
            'see who reported.',
            style: style,
          ),
        ),
      ],
    );
  }
}
