// Fake corridor repository with sample data.
import 'dart:async';

import '../domain/entities/corridor.dart';
import '../domain/entities/corridor_stats.dart';
import '../domain/repositories/corridor_repository.dart';

class FakeCorridorRepository implements CorridorRepository {
  //the routes can be reversed. it's the same thing
  static const _allCorridors = [
    Corridor(id: 'alu-downtown', fromArea: 'ALU', toArea: 'Downtown'),
    Corridor(id: 'downtown-alu', fromArea: 'Downtown', toArea: 'ALU'),
    Corridor(id: 'kacyiru-kimironko', fromArea: 'Kacyiru', toArea: 'Kimironko'),
    Corridor(id: 'kimironko-kacyiru', fromArea: 'Kimironko', toArea: 'Kacyiru'),
    Corridor(id: 'remera-downtown', fromArea: 'Remera', toArea: 'Downtown'),
    Corridor(id: 'downtown-remera', fromArea: 'Downtown', toArea: 'Remera'),
    Corridor(id: 'gisozi-kacyiru', fromArea: 'Gisozi', toArea: 'Kacyiru'),
    Corridor(id: 'kacyiru-gisozi', fromArea: 'Kacyiru', toArea: 'Gisozi'),
  ];

  //the fake prices, one for each corridor id
  final Map<String, CorridorStats> _allStats = {
    'alu-downtown': CorridorStats(
      corridorId: 'alu-downtown',
      median: 2000,
      low: 1500,
      high: 2500,
      sampleSize: 24,
      confidence: 'wellCovered',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    'downtown-alu': CorridorStats(
      corridorId: 'downtown-alu',
      median: 2000,
      low: 1500,
      high: 2500,
      sampleSize: 8,
      confidence: 'limited',
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    'kacyiru-kimironko': CorridorStats(
      corridorId: 'kacyiru-kimironko',
      median: 1200,
      low: 1000,
      high: 1500,
      sampleSize: 3,
      confidence: 'new',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    'kimironko-kacyiru': CorridorStats(
      corridorId: 'kimironko-kacyiru',
      median: 1200,
      low: 1000,
      high: 1500,
      sampleSize: 3,
      confidence: 'new',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    'remera-downtown': CorridorStats(
      corridorId: 'remera-downtown',
      median: 1200,
      low: 1000,
      high: 1500,
      sampleSize: 21,
      confidence: 'wellCovered',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    'gisozi-kacyiru': CorridorStats(
      corridorId: 'gisozi-kacyiru',
      median: 1000,
      low: 800,
      high: 1200,
      sampleSize: 6,
      confidence: 'limited',
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  };

  //give back the stats for one corridor or return null
  @override
  Stream<CorridorStats?> watchStats(String corridorId) async* {
    await Future.delayed(const Duration(milliseconds: 300));
    yield _allStats[corridorId];
  }

  //find corridors where the from or to area contains what was typed
  @override
  Future<List<Corridor>> searchCorridors(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lower = query.toLowerCase();
    return _allCorridors.where((c) {
      return c.fromArea.toLowerCase().contains(lower) ||
          c.toArea.toLowerCase().contains(lower);
    }).toList();
  }

  //return all the fake corridors
  @override
  Future<List<Corridor>> popularCorridors() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _allCorridors;
  }
}
