//this screen is the corridors tab. Pick a pickup and a dropoff to see the price
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/chip_row.dart';
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
import 'route_picker.dart';

class CorridorsScreen extends ConsumerStatefulWidget {
  const CorridorsScreen({super.key});

  @override
  ConsumerState<CorridorsScreen> createState() => _CorridorsScreenState();
}

class _CorridorsScreenState extends ConsumerState<CorridorsScreen> {
  //the areas the student picked for the route
  Zone? pickup;
  Zone? dropoff;
  bool findingLocation = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  //swap the pickup and the dropoff
  void swapZones() {
    setState(() {
      final temp = pickup;
      pickup = dropoff;
      dropoff = temp;
    });
  }

  //a chip sets both areas of its route
  void pickRoute(Corridor corridor, List<Zone> zones) {
    final from = zones.where((zone) => zone.name == corridor.fromArea).firstOrNull;
    final to = zones.where((zone) => zone.name == corridor.toArea).firstOrNull;
    if (from == null || to == null) return;
    setState(() {
      pickup = from;
      dropoff = to;
    });
  }

  //finds the area nearest to the phone and uses it as the pickup
  Future<void> useMyLocation(List<Zone> zones) async {
    setState(() => findingLocation = true);
    final result = await ref.read(locationServiceProvider).getLocation();
    if (!mounted) return;
    setState(() => findingLocation = false);

    if (result.status == LocationStatus.found) {
      final zone = findNearestZone(result.latitude!, result.longitude!, zones);
      if (zone == null) {
        showMessage('You are outside our areas. Type your pickup instead');
        return;
      }
      setState(() => pickup = zone);
      return;
    }

    //something went wrong, tell the student what to do
    if (result.status == LocationStatus.serviceOff) {
      showMessage('Location is turned off. Turn it on or type your pickup');
    } else if (result.status == LocationStatus.denied) {
      showMessage('Location was not allowed. You can type your pickup');
    } else if (result.status == LocationStatus.deniedForever) {
      showMessage('Location is blocked for this app. Turn it on in your phone settings');
    } else {
      showMessage('Could not find your location. Type your pickup instead');
    }
  }

  // runs when a student taps the price card
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
          content: const Text('Could not load this price. Check your connection'),
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

  //the price card for the chosen pickup and dropoff
  Widget routePrice(Zone from, Zone to) {
    if (from.id == to.id) {
      return const Text('Pick two different areas');
    }

    //same id the seed script makes. like alu-downtown
    final corridor = Corridor(
      id: '${from.id}-${to.id}',
      fromArea: from.name,
      toArea: to.name,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CorridorTile(corridor: corridor, onTap: () => pickCorridor(corridor)),
        const SizedBox(height: AppSpacing.sm),
        Text('Tap the card for a negotiation tip',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final zones = ref.watch(zonesProvider);
    final popular = ref.watch(popularCorridorsProvider);

    //the id of the route that is chosen now, so its chip is highlighted
    final chosenId = (pickup != null && dropoff != null)
        ? '${pickup!.id}-${dropoff!.id}'
        : null;

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

              zones.when(
                data: (zones) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //pickup and dropoff
                    RoutePicker(
                      zones: zones,
                      pickup: pickup,
                      dropoff: dropoff,
                      onPickup: (zone) => setState(() => pickup = zone),
                      onDropoff: (zone) => setState(() => dropoff = zone),
                      onSwap: swapZones,
                      onUseLocation: () => useMyLocation(zones),
                      findingLocation: findingLocation,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    //popular routes
                    Text('Popular routes', style: text.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    popular.when(
                      data: (corridors) => ChipRow(
                        corridors: corridors,
                        selectedId: chosenId,
                        onPick: (corridor) => pickRoute(corridor, zones),
                      ),
                      loading: () =>
                      const SizedBox(height: AppSpacing.minTapTarget),
                      error: (error, stack) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    //the price of the chosen route
                    if (pickup != null && dropoff != null)
                      routePrice(pickup!, dropoff!),
                  ],
                ),
                loading: () => const SizedBox(height: 120, child: LoadingView()),
                error: (error, stack) => ErrorView(
                  compact: true,
                  onRetry: () => ref.invalidate(zonesProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//the price card. loads its own prices
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