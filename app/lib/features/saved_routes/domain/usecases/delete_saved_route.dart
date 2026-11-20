// Delete a saved route.
import '../../../../core/errors/failures.dart';
import '../repositories/saved_route_repository.dart';

class DeleteSavedRoute {
  final SavedRouteRepository repository;

  DeleteSavedRoute(this.repository);

  Future<void> call(String routeId) {
    if (routeId.isEmpty) throw const ValidationFailure('Choose a saved route');
    return repository.delete(routeId);
  }
}
