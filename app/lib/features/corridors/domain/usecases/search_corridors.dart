// Search corridors by query string.
import '../entities/corridor.dart';
import '../repositories/corridor_repository.dart';

class SearchCorridors {
  final CorridorRepository repository;

  SearchCorridors(this.repository);

  Future<List<Corridor>> call(String query) {
    return repository.searchCorridors(query);
  }
}
