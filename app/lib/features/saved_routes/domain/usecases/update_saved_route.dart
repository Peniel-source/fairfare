// Update a saved route.
import '../../../../core/errors/failures.dart';
import '../entities/saved_route.dart';
import '../repositories/saved_route_repository.dart';
import '../saved_route_validation.dart';

class UpdateSavedRoute {
  final SavedRouteRepository repository;

  UpdateSavedRoute(this.repository);

  Future<void> call(SavedRoute route) {
    if (route.id.isEmpty) throw const ValidationFailure('Choose a saved route');
    return repository.update(SavedRouteValidation.normalized(route));
  }
}
