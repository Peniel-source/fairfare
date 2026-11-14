// Watch corridor stats for a specific corridor.
import '../entities/corridor_stats.dart';
import '../repositories/corridor_repository.dart';

class WatchCorridorStats {
  final CorridorRepository repository;

  WatchCorridorStats(this.repository);

  Stream<CorridorStats?> call(String corridorId) {
    return repository.watchStats(corridorId);
  }
}
