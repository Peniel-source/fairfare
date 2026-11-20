import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/saved_route.dart';
import '../domain/repositories/saved_route_repository.dart';

class FirestoreSavedRouteRepository implements SavedRouteRepository {
  FirestoreSavedRouteRepository(this._firestore, this._passengerId);

  final FirebaseFirestore _firestore;
  final String _passengerId;

  CollectionReference<Map<String, dynamic>> get _routes => _firestore
      .collection(FirestorePaths.passengers)
      .doc(_passengerId)
      .collection(FirestorePaths.savedRoutes);

  @override
  Stream<List<SavedRoute>> watchAll() async* {
    try {
      await for (final snapshot
          in _routes.orderBy('createdAt', descending: true).snapshots()) {
        yield List.unmodifiable(
          snapshot.docs.map((document) {
            final data = document.data();
            return SavedRoute(
              id: document.id,
              fromArea: data['fromArea'] as String,
              toArea: data['toArea'] as String,
              label: data['label'] as String,
            );
          }),
        );
      }
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  Map<String, dynamic> _fields(SavedRoute route) => {
    'fromArea': route.fromArea,
    'toArea': route.toArea,
    'label': route.label,
  };

  @override
  Future<void> add(SavedRoute route) => _run(() async {
    await _routes.add({
      ..._fields(route),
      'createdAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> update(SavedRoute route) =>
      _run(() => _routes.doc(route.id).update(_fields(route)));

  @override
  Future<void> delete(String routeId) =>
      _run(() => _routes.doc(routeId).delete());

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  Failure _failure(FirebaseException error) => switch (error.code) {
    'unavailable' || 'deadline-exceeded' => const NetworkFailure(),
    'permission-denied' || 'unauthenticated' => const AuthFailure(
      'Sign in again to manage your saved routes',
    ),
    'not-found' => const FirestoreFailure('This saved route no longer exists'),
    _ => const FirestoreFailure(
      'Could not save your changes. Please try again',
    ),
  };
}
