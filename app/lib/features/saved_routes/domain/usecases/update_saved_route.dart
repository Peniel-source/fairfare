// Update a saved route.
import '../entities/saved_route.dart';
import '../repositories/saved_route_repository.dart';

class UpdateSavedRoute {
  final SavedRouteRepository repository;

  UpdateSavedRoute(this.repository);

  Future<void> call(SavedRoute route) {
    return repository.update(route);
  }
}
