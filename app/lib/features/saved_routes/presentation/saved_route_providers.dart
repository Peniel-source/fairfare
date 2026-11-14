// Riverpod providers for the saved routes feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/fake_saved_route_repository.dart';
import '../domain/entities/saved_route.dart';
import '../domain/repositories/saved_route_repository.dart';
import '../domain/usecases/add_saved_route.dart';
import '../domain/usecases/update_saved_route.dart';
import '../domain/usecases/delete_saved_route.dart';

/// Provider for the SavedRouteRepository implementation.
final savedRouteRepositoryProvider = Provider<SavedRouteRepository>((ref) {
  if (AppConstants.useFakeData) {
    return FakeSavedRouteRepository();
  }
  // TODO(B5): return SavedRouteRepositoryImpl() when real Firestore wiring is ready.
  throw UnimplementedError('SavedRouteRepositoryImpl not yet implemented');
});

/// Stream of all saved routes for the current passenger.
final savedRoutesProvider = StreamProvider<List<SavedRoute>>((ref) {
  return ref.watch(savedRouteRepositoryProvider).watchAll();
});

/// Use case providers.
final addSavedRouteProvider = Provider<AddSavedRoute>((ref) {
  return AddSavedRoute(ref.watch(savedRouteRepositoryProvider));
});

final updateSavedRouteProvider = Provider<UpdateSavedRoute>((ref) {
  return UpdateSavedRoute(ref.watch(savedRouteRepositoryProvider));
});

final deleteSavedRouteProvider = Provider<DeleteSavedRoute>((ref) {
  return DeleteSavedRoute(ref.watch(savedRouteRepositoryProvider));
});
