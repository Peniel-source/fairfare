import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../corridors/domain/entities/corridor.dart';
import '../../corridors/domain/entities/corridor_stats.dart';
import '../../corridors/presentation/corridor_providers.dart';

class LandingFare {
  const LandingFare({required this.corridor, required this.stats});

  final Corridor corridor;
  final CorridorStats stats;
}

final landingFareProvider = StreamProvider.autoDispose<LandingFare?>((
  ref,
) async* {
  final repository = ref.watch(corridorRepositoryProvider);
  final corridors = await repository.popularCorridors();
  if (corridors.isEmpty) {
    yield null;
    return;
  }

  final corridor = corridors.first;
  await for (final stats in repository.watchStats(corridor.id)) {
    yield stats == null || stats.sampleSize == 0
        ? null
        : LandingFare(corridor: corridor, stats: stats);
  }
});
