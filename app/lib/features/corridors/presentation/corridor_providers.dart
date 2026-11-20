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
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/zone_impl.dart';
import '../data/corridor_impl.dart';

final corridorRepositoryProvider = Provider<CorridorRepository>((ref) {
  if (AppConstants.useFakeData) {
    return FakeCorridorRepository();
  }
  return CorridorRepositoryImpl(FirebaseFirestore.instance);
});

final searchCorridorsProvider = Provider<SearchCorridors>((ref) {
  return SearchCorridors(ref.watch(corridorRepositoryProvider));
});

final watchCorridorStatsProvider = Provider<WatchCorridorStats>((ref) {
  return WatchCorridorStats(ref.watch(corridorRepositoryProvider));
});

final corridorStatsProvider = StreamProvider.family<CorridorStats?, String>((
  ref,
  corridorId,
) {
  return ref.watch(corridorRepositoryProvider).watchStats(corridorId);
});

final popularCorridorsProvider = FutureProvider<List<Corridor>>((ref) {
  return ref.watch(corridorRepositoryProvider).popularCorridors();
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
  return ZoneRepositoryImpl(FirebaseFirestore.instance);
});

// the list of zones for the pickup and dropoff fields
final zonesProvider = FutureProvider<List<Zone>>((ref) {
  return ref.watch(zoneRepositoryProvider).getZones();
});

// asks the phone for its location
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
