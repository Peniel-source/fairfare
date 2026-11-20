// Search corridors by query string.
import '../entities/corridor.dart';
import '../repositories/corridor_repository.dart';

class SearchCorridors {
  final CorridorRepository repository;

  SearchCorridors(this.repository);

  Future<List<Corridor>> call(String query, {String? toArea}) async {
    final corridors = await repository.searchCorridors(query.trim());
    if (toArea == null) return corridors;
    final from = query.trim().toLowerCase();
    final to = toArea.trim().toLowerCase();
    return corridors
        .where(
          (corridor) =>
              corridor.fromArea.toLowerCase() == from &&
              corridor.toArea.toLowerCase() == to,
        )
        .toList();
  }
}
