// Delete a saved route.
import '../repositories/saved_route_repository.dart';

class DeleteSavedRoute {
  final SavedRouteRepository repository;

  DeleteSavedRoute(this.repository);

  Future<void> call(String routeId) {
    return repository.delete(routeId);
  }
}
