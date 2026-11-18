import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_banner.dart';
import '../../corridors/domain/entities/corridor_stats.dart';
import '../domain/entities/report.dart';
import '../domain/entities/report_enums.dart';
import '../domain/expected_band.dart';

/// Snackbar message for a failed submit
String reportErrorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'Could not send your report. Check your connection and try again.';
}

/// Band check preview
class BandPreviewBanner extends StatelessWidget {
  const BandPreviewBanner({
    super.key,
    required this.stats,
    required this.price,
    required this.timeSegment,
    required this.weather,
  });

  final AsyncValue<CorridorStats?> stats;
  final int price;
  final TimeSegment timeSegment;
  final Weather weather;

  @override
  Widget build(BuildContext context) {
    if (stats.isLoading && !stats.hasValue) {
      return const StatusBanner(
        tone: StatusTone.info,
        title: 'Checking the usual price for this route…',
        child: LinearProgressIndicator(),
      );
    }
    if (stats.hasError) {
      return const StatusBanner(
        tone: StatusTone.warning,
        title: 'Could not load the usual price',
        message: 'You can still submit. The server checks the price.',
      );
    }

    final preview = previewBand(
      stats: stats.value,
      price: price,
      timeSegment: timeSegment,
      weather: weather,
    );
    final band = preview.band;
    final range = band == null
        ? ''
        : Formatters.priceRange(band.low, band.high);

    return switch (preview.verdict) {
      BandVerdict.within => StatusBanner(
        tone: StatusTone.success,
        title: 'Within expected band ($range)',
        tag: 'Provisionally accepted',
        message:
            'It then waits up to 48 hours for another passenger to confirm '
            'a similar price.',
        child: BandRangeBar(band: band!, price: price),
      ),
      BandVerdict.outside => StatusBanner(
        tone: StatusTone.warning,
        title: 'Outside the usual range ($range)',
        tag: 'May be rejected',
        message:
            'Check the price. Reports far from the usual price for this '
            'route are rejected by the band check.',
        child: BandRangeBar(band: band!, price: price),
      ),
      BandVerdict.newCorridor => const StatusBanner(
        tone: StatusTone.info,
        icon: Icons.explore_outlined,
        title: 'New route: not enough price history yet',
        message:
            'The band check is skipped. Your report is verified when another '
            'passenger confirms a similar price within 48 hours.',
      ),
    };
  }
}

/// Min, your price and max
class BandRangeBar extends StatelessWidget {
  const BandRangeBar({super.key, required this.band, required this.price});

  final PriceBand band;
  final int price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = theme.extension<AppPalette>()?.accent ?? scheme.primary;
    final span = (band.high - band.low).clamp(1, 1 << 31);
    final position = ((price - band.low) / span).clamp(0.0, 1.0);
    final caption = theme.textTheme.bodySmall;

    return Semantics(
      label:
          'Your price ${Formatters.price(price)}, accepted range '
          '${Formatters.priceRange(band.low, band.high)}',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const marker = 16.0;
                final left = (constraints.maxWidth - marker) * position;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.pillRadius,
                        gradient: LinearGradient(
                          colors: [
                            accent.withValues(alpha: 0.35),
                            accent,
                            accent.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: left,
                      child: Container(
                        width: marker,
                        height: marker,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.surfaceContainerLowest,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${Formatters.price(band.low)}\nMin',
                  style: caption,
                ),
              ),
              Expanded(
                child: Text(
                  '${Formatters.price(price)}\nYou',
                  textAlign: TextAlign.center,
                  style: caption?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${Formatters.price(band.high)}\nMax',
                  textAlign: TextAlign.end,
                  style: caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Status of the submitted report with the 48h countdown
class SubmittedReportBanner extends StatelessWidget {
  const SubmittedReportBanner({
    super.key,
    required this.report,
    required this.now,
    required this.onReportAnother,
    required this.onOpenMyReports,
  });

  final Report? report;
  final DateTime now;
  final VoidCallback onReportAnother;
  final VoidCallback onOpenMyReports;

  @override
  Widget build(BuildContext context) {
    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: onReportAnother,
          icon: const Icon(Icons.add),
          label: const Text('Report another ride'),
        ),
        TextButton(onPressed: onOpenMyReports, child: const Text('My reports')),
      ],
    );

    final report = this.report;
    if (report == null) {
      return const StatusBanner(
        tone: StatusTone.info,
        title: 'Report sent',
        tag: 'Pending',
        message: 'Waiting for it to appear in your reports…',
      );
    }

    return switch (report.status) {
      ReportStatus.pending => StatusBanner(
        tone: StatusTone.info,
        icon: Icons.hourglass_top,
        title: 'Report submitted',
        tag: 'Pending',
        message:
            'Waiting for another passenger to report a similar price. '
            'Time left: ${Formatters.countdown(_timeLeft(report))}',
        child: actions,
      ),
      ReportStatus.verified => StatusBanner(
        tone: StatusTone.success,
        title: 'Report verified',
        tag: 'Verified',
        message:
            'Another passenger confirmed this price. Your reward is on its '
            'way to your wallet.',
        child: actions,
      ),
      ReportStatus.rejected => StatusBanner(
        tone: StatusTone.error,
        title: 'Report rejected',
        tag: 'Rejected',
        message:
            report.reason ??
            'The price was far outside the usual range for this route.',
        child: actions,
      ),
      ReportStatus.expired => StatusBanner(
        tone: StatusTone.warning,
        title: 'Report expired',
        tag: 'Expired',
        message:
            'No one confirmed a similar price within 48 hours. '
            'No reward, and no penalty.',
        child: actions,
      ),
    };
  }

  Duration _timeLeft(Report report) =>
      report.createdAt.add(AppConstants.corroborationWindow).difference(now);
}
