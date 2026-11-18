//this screen is the corridors tab. It has search a route
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/chip_row.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/home_app_bar.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/entities/corridor.dart';
import '../domain/entities/corridor_stats.dart';
import 'corridor_card.dart';
import 'corridor_providers.dart';

class CorridorsScreen extends ConsumerStatefulWidget {
  const CorridorsScreen({super.key});

  @override
  ConsumerState<CorridorsScreen> createState() => _CorridorsScreenState();
}

class _CorridorsScreenState extends ConsumerState<CorridorsScreen> {
  String query = '';

  // runs when a student taps a chip or a card
  Future<void> pickCorridor(Corridor corridor) async {
    // remember it, the report form uses this later
    ref.read(settingsProvider.notifier).setLastCorridorId(corridor.id);

    final stats = await ref.read(corridorStatsProvider(corridor.id).future);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => TipSheet(corridor: corridor, stats: stats),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lastCorridorId = ref.watch(
      settingsProvider.select((settings) => settings.lastCorridorId),
    );
    final popular = ref.watch(popularCorridorsProvider);
    final results = ref.watch(corridorSearchProvider(query));

    return Scaffold(
      appBar: const HomeAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              Text('How much do you pay?', style: text.headlineSmall),
              const SizedBox(height: AppSpacing.lg),

              //search box
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search an area, like Kimironko',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => query = value.trim()),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Popular routes', style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              popular.when(
                data: (corridors) => ChipRow(
                  corridors: corridors,
                  selectedId: lastCorridorId,
                  onPick: pickCorridor,
                ),
                loading: () => const SizedBox(height: AppSpacing.minTapTarget),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.lg),

              //the list of cards
              Text('All routes', style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              results.when(
                data: (corridors) {
                  if (corridors.isEmpty) {
                    return const EmptyView(
                      compact: true,
                      icon: Icons.search_off,
                      title: 'No routes found',
                      message: 'Try another area name.',
                    );
                  }
                  return Column(
                    children: [
                      for (final corridor in corridors)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: CorridorTile(
                            corridor: corridor,
                            onTap: () => pickCorridor(corridor),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 120, child: LoadingView()),
                error: (error, stack) => ErrorView(
                  compact: true,
                  onRetry: () => ref.invalidate(corridorSearchProvider(query)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//one card in the list. load its own prices
class CorridorTile extends ConsumerWidget {
  const CorridorTile({super.key, required this.corridor, required this.onTap});

  final Corridor corridor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(corridorStatsProvider(corridor.id));

    return stats.when(
      data: (stats) =>
          CorridorCard(corridor: corridor, stats: stats, onTap: onTap),
      loading: () => AppCard(
        child: Text('${corridor.fromArea} to ${corridor.toArea}, loading price'),
      ),
      error: (error, stack) => AppCard(
        onTap: onTap,
        child: Text('${corridor.fromArea} to ${corridor.toArea}, price not available'),
      ),
    );
  }
}

//sheet for negotiation tip
class TipSheet extends StatelessWidget {
  const TipSheet({super.key, required this.corridor, required this.stats});

  final Corridor corridor;
  final CorridorStats? stats;

  //build the tip from the three prices
  String tipText(CorridorStats stats) {
    var tip =
        'Start with ${Formatters.price(stats.low)}. '
        'A fair price is around ${Formatters.price(stats.median)}. '
        'If the rider asks for more than ${Formatters.price(stats.high)}, '
        'that is more than the range';
    if (stats.confidence == 'new') {
      tip += ' Only a few reports so far, so we might be wrong';
    }
    return tip;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${corridor.fromArea} to ${corridor.toArea}',
            style: text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            stats == null
                ? 'Nobody has reported this route yet. Ask the rider first, then share what you paid'
                : tipText(stats!),
            style: text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Report what you paid',
            onPressed: () {
              Navigator.pop(context);
              context.go('/home/report');
            },
          ),
        ],
      ),
    );
  }
}