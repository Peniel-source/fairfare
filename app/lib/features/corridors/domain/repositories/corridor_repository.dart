// Repository for corridor lookups and stats.
import '../entities/corridor.dart';
import '../entities/corridor_stats.dart';

abstract class CorridorRepository {
  Stream<CorridorStats?> watchStats(String corridorId);
  Future<List<Corridor>> searchCorridors(String query);
  Future<List<Corridor>> popularCorridors();
}
