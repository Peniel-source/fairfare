// Riverpod providers for the saved routes feature.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/firestore_saved_route_repository.dart';
import '../domain/entities/saved_route.dart';
import '../domain/repositories/saved_route_repository.dart';
import '../domain/usecases/add_saved_route.dart';
import '../domain/usecases/update_saved_route.dart';
import '../domain/usecases/delete_saved_route.dart';

/// Provider for the SavedRouteRepository implementation.
final savedRoutesFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final savedRouteRepositoryProvider = Provider<SavedRouteRepository>((ref) {
  final uid = ref.watch(
    authStateProvider.select((auth) => auth.valueOrNull?.id),
  );
  if (uid == null) {
    throw const AuthFailure('Sign in to manage your saved routes');
  }
  return FirestoreSavedRouteRepository(
    ref.watch(savedRoutesFirestoreProvider),
    uid,
  );
});

/// Stream of all saved routes for the current passenger.
final savedRoutesProvider = StreamProvider.autoDispose<List<SavedRoute>>((ref) {
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

String savedRouteErrorMessage(Object error) => error is Failure
    ? error.message
    : 'Could not load your saved routes. Please try again';
