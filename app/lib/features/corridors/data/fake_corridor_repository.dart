// Fake corridor repository with sample data.
import 'dart:async';

import '../domain/entities/corridor.dart';
import '../domain/entities/corridor_stats.dart';
import '../domain/repositories/corridor_repository.dart';

class FakeCorridorRepository implements CorridorRepository {
  static const _sampleCorridors = [
    Corridor(id: 'c1', fromArea: 'Kacyiru', toArea: 'Kimironko'),
    Corridor(id: 'c2', fromArea: 'Kigali', toArea: 'Nyarugenge'),
    Corridor(id: 'c3', fromArea: 'Gisozi', toArea: 'Kacyiru'),
    Corridor(id: 'c4', fromArea: 'Kimironko', toArea: 'Huye'),
    Corridor(id: 'c5', fromArea: 'Remera', toArea: 'Kacyiru'),
  ];

  static final _sampleStats = CorridorStats(
    corridorId: 'c1',
    median: 600,
    low: 500,
    high: 800,
    sampleSize: 24,
    confidence: 'Well covered',
    updatedAt: DateTime(2026),
  );

  @override
  Stream<CorridorStats?> watchStats(String corridorId) async* {
    await Future.delayed(const Duration(milliseconds: 300));
    yield corridorId == 'c1' ? _sampleStats : null;
  }

  @override
  Future<List<Corridor>> searchCorridors(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lower = query.toLowerCase();
    return _sampleCorridors.where((c) {
      return c.fromArea.toLowerCase().contains(lower) ||
          c.toArea.toLowerCase().contains(lower);
    }).toList();
  }

  @override
  Future<List<Corridor>> popularCorridors() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _sampleCorridors;
  }
}
