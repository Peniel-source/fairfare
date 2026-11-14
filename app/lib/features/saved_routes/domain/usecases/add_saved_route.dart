// Add a saved route.
import '../entities/saved_route.dart';
import '../repositories/saved_route_repository.dart';

class AddSavedRoute {
  final SavedRouteRepository repository;

  AddSavedRoute(this.repository);

  Future<void> call(SavedRoute route) {
    return repository.add(route);
  }
}
