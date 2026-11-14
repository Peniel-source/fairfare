// Fake saved routes repository with sample data.
import 'dart:async';

import '../domain/entities/saved_route.dart';
import '../domain/repositories/saved_route_repository.dart';

class FakeSavedRouteRepository implements SavedRouteRepository {
  final _controller = StreamController<List<SavedRoute>>.broadcast();
  final _routes = <SavedRoute>[
    const SavedRoute(
      id: 'sr1',
      fromArea: 'Kacyiru',
      toArea: 'Kimironko',
      label: 'Work',
    ),
    const SavedRoute(
      id: 'sr2',
      fromArea: 'Gisozi',
      toArea: 'Kacyiru',
      label: 'Home',
    ),
  ];

  FakeSavedRouteRepository() {
    _controller.add(_routes);
  }

  @override
  Stream<List<SavedRoute>> watchAll() => _controller.stream;

  @override
  Future<void> add(SavedRoute route) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _routes.add(route);
    _controller.add(_routes);
  }

  @override
  Future<void> update(SavedRoute route) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _routes.indexWhere((r) => r.id == route.id);
    if (index != -1) {
      _routes[index] = route;
      _controller.add(_routes);
    }
  }

  @override
  Future<void> delete(String routeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _routes.removeWhere((r) => r.id == routeId);
    _controller.add(_routes);
  }

  void dispose() => _controller.close();
}
