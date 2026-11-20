// Riverpod providers for the corridors feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/fake_corridor_repository.dart';
import '../domain/entities/corridor.dart';
import '../domain/entities/corridor_stats.dart';
import '../domain/repositories/corridor_repository.dart';
import '../domain/usecases/search_corridors.dart';
import '../domain/usecases/watch_corridor_stats.dart';
import '../data/location_service.dart';
import '../data/zone_repository.dart';
import '../domain/zone_finder.dart';

/// Provider for the CorridorRepository implementation.
final corridorRepositoryProvider = Provider<CorridorRepository>((ref) {
  if (AppConstants.useFakeData) {
    return FakeCorridorRepository();
  }
  // TODO(A5): return CorridorRepositoryImpl() when real Firestore wiring is ready.
  throw UnimplementedError('CorridorRepositoryImpl not yet implemented');
});

/// Use case providers.
final searchCorridorsProvider = Provider<SearchCorridors>((ref) {
  return SearchCorridors(ref.watch(corridorRepositoryProvider));
});

final watchCorridorStatsProvider = Provider<WatchCorridorStats>((ref) {
  return WatchCorridorStats(ref.watch(corridorRepositoryProvider));
});

/// Stream of corridor stats for a specific corridor id.
final corridorStatsProvider = StreamProvider.family<CorridorStats?, String>((
  ref,
  corridorId,
) {
  return ref.watch(corridorRepositoryProvider).watchStats(corridorId);
});

/// Future provider for popular corridors.
final popularCorridorsProvider = FutureProvider<List<Corridor>>((ref) {
  return ref.watch(corridorRepositoryProvider).popularCorridors();
});

final corridorRouteProvider =
    FutureProvider.family<List<Corridor>, ({String fromArea, String toArea})>((
      ref,
      route,
    ) {
      return ref.watch(searchCorridorsProvider)(
        route.fromArea,
        toArea: route.toArea,
      );
    });

//the corridors that match what the usr typed
final corridorSearchProvider = FutureProvider.family<List<Corridor>, String>((
  ref,
  query,
) {
  return ref.watch(searchCorridorsProvider)(query);
});

// the repository that gives the list of zones
final zoneRepositoryProvider = Provider<ZoneRepository>((ref) {
  if (AppConstants.useFakeData) {
    return FakeZoneRepository();
  }
  throw UnimplementedError('ZoneRepositoryImpl not yet implemented');
});

// the list of zones for the pickup and dropoff fields
final zonesProvider = FutureProvider<List<Zone>>((ref) {
  return ref.watch(zoneRepositoryProvider).getZones();
});

// asks the phone for its location
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
