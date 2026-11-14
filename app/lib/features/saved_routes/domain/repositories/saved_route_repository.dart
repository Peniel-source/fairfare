// Repository for saved favorite routes.
import '../entities/saved_route.dart';

abstract class SavedRouteRepository {
  Stream<List<SavedRoute>> watchAll();
  Future<void> add(SavedRoute route);
  Future<void> update(SavedRoute route);
  Future<void> delete(String routeId);
}
