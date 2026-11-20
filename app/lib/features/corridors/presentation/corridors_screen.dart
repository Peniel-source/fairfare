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
import '../data/location_service.dart';
import '../domain/entities/corridor.dart';
import '../domain/entities/corridor_stats.dart';
import '../domain/zone_finder.dart';
import 'corridor_card.dart';
import 'corridor_providers.dart';

class CorridorsScreen extends ConsumerStatefulWidget {
  const CorridorsScreen({super.key, this.fromArea, this.toArea});

  final String? fromArea;
  final String? toArea;

  @override
  ConsumerState<CorridorsScreen> createState() => _CorridorsScreenState();
}

class _CorridorsScreenState extends ConsumerState<CorridorsScreen> {
  final searchBox = TextEditingController();
  String query = '';
  bool findingLocation = false;

  @override
  void dispose() {
    searchBox.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  //what to tell the student when the location could not be found
  String locationMessage(LocationStatus status) {
    if (status == LocationStatus.serviceOff) {
      return 'Location is turned off. Turn it on or search an area';
    }
    if (status == LocationStatus.denied) {
      return 'Location was not allowed. You can search an area';
    }
    if (status == LocationStatus.deniedForever) {
      return 'Location is blocked for this app. Turn it on in your phone settings';
    }
    return 'Could not find your location. Search an area instead';
  }

  //finds the area nearest to the phone and puts its name in the search box
  Future<void> useMyLocation() async {
    setState(() => findingLocation = true);
    final result = await ref.read(locationServiceProvider).getLocation();

    if (result.status != LocationStatus.found) {
      if (!mounted) return;
      setState(() => findingLocation = false);
      showMessage(locationMessage(result.status));
      return;
    }

    try {
      final zones = await ref.read(zonesProvider.future);
      if (!mounted) return;
      final zone = findNearestZone(result.latitude!, result.longitude!, zones);
      setState(() => findingLocation = false);

      if (zone == null) {
        showMessage('You are outside our areas. Search an area instead');
        return;
      }
      searchBox.text = zone.name;
      setState(() => query = zone.name);
    } catch (error) {
      if (!mounted) return;
      setState(() => findingLocation = false);
      showMessage('Could not load the areas. Check your connection');
    }
  }

  // runs when a student taps a chip or a card
  Future<void> pickCorridor(Corridor corridor) async {
    // remember it, the report form uses this later
    ref.read(settingsProvider.notifier).setLastCorridorId(corridor.id);

    try {
      final stats = await ref.read(corridorStatsProvider(corridor.id).future);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => TipSheet(corridor: corridor, stats: stats),
      );
    } catch (error) {
      if (!mounted) return;
      // the price could not load, let the student try again
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not load this price. Check your connection',
          ),
          action: SnackBarAction(
            label: 'Try again',
            onPressed: () {
              ref.invalidate(corridorStatsProvider(corridor.id));
              pickCorridor(corridor);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lastCorridorId = ref.watch(
      settingsProvider.select((settings) => settings.lastCorridorId),
    );
    final popular = ref.watch(popularCorridorsProvider);
    final savedRoute = widget.fromArea != null && widget.toArea != null;
    final results = savedRoute
        ? ref.watch(
            corridorRouteProvider((
              fromArea: widget.fromArea!,
              toArea: widget.toArea!,
            )),
          )
        : ref.watch(corridorSearchProvider(query));

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'How much do you pay?',
                      style: text.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Saved routes',
                    onPressed: () => context.pushNamed('savedRoutes'),
                    icon: const Icon(Icons.bookmarks_outlined),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              if (savedRoute)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.fromArea} → ${widget.toArea}',
                        style: text.titleSmall,
                      ),
                    ),
                    AppButton(
                      label: 'All routes',
                      onPressed: () => context.goNamed('corridors'),
                      variant: AppButtonVariant.text,
                    ),
                  ],
                )
              else
                TextField(
                  controller: searchBox,
                  decoration: InputDecoration(
                    hintText: 'Search an area, like Kimironko',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: findingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            tooltip: 'Use my location',
                            icon: const Icon(Icons.my_location),
                            onPressed: useMyLocation,
                          ),
                  ),
                  onChanged: (value) => setState(() => query = value.trim()),
                ),
              const SizedBox(height: AppSpacing.lg),

              if (!savedRoute) ...[
                Text('Popular routes', style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                popular.when(
                  data: (corridors) => ChipRow(
                    corridors: corridors,
                    selectedId: lastCorridorId,
                    onPick: pickCorridor,
                  ),
                  loading: () =>
                      const SizedBox(height: AppSpacing.minTapTarget),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              //the list of cards
              Text(
                savedRoute ? 'Your route' : 'All routes',
                style: text.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              results.when(
                data: (corridors) {
                  if (corridors.isEmpty) {
                    return EmptyView(
                      compact: true,
                      icon: Icons.search_off,
                      title: savedRoute
                          ? 'Route not available yet'
                          : 'No routes found',
                      message: savedRoute
                          ? 'Show all routes to choose another corridor.'
                          : 'Try another area name.',
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
                loading: () =>
                    const SizedBox(height: 120, child: LoadingView()),
                error: (error, stack) => ErrorView(
                  compact: true,
                  onRetry: () {
                    if (savedRoute) {
                      ref.invalidate(
                        corridorRouteProvider((
                          fromArea: widget.fromArea!,
                          toArea: widget.toArea!,
                        )),
                      );
                    } else {
                      ref.invalidate(corridorSearchProvider(query));
                    }
                  },
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
        child: Text(
          '${corridor.fromArea} to ${corridor.toArea}, loading price',
        ),
      ),
      error: (error, stack) => AppCard(
        onTap: onTap,
        child: Text(
          '${corridor.fromArea} to ${corridor.toArea}, price not available',
        ),
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

    return SingleChildScrollView(
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
