//reads the corridors and their prices from firestore. the real version of the corridor list
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../domain/entities/corridor.dart';
import '../domain/entities/corridor_stats.dart';
import '../domain/repositories/corridor_repository.dart';

//the most routes the list shows at once
const maxRoutes = 20;
//how many routes the chips show
const maxPopular = 8;

class CorridorRepositoryImpl implements CorridorRepository {
  CorridorRepositoryImpl(this.firestore);

  final FirebaseFirestore firestore;

  //all the corridors, loaded one time and kept. the app cannot change them
  List<Corridor>? allCorridors;

  Corridor corridorFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Corridor(
      id: doc.id,
      fromArea: doc.get('fromArea') as String,
      toArea: doc.get('toArea') as String,
    );
  }

  Future<List<Corridor>> loadAllCorridors() async {
    final saved = allCorridors;
    if (saved != null) return saved;

    final snapshot = await firestore
        .collection(FirestorePaths.corridors)
        .orderBy('fromArea')
        .get();
    final corridors = [for (final doc in snapshot.docs) corridorFromDoc(doc)];
    allCorridors = corridors;
    return corridors;
  }

  //the corridors that have prices, the ones with the most reports first
  Future<List<Corridor>> corridorsWithPrices(int limit) async {
    final statsSnapshot = await firestore
        .collection(FirestorePaths.corridorStats)
        .orderBy('sampleSize', descending: true)
        .limit(limit)
        .get();
    final all = await loadAllCorridors();

    final corridors = <Corridor>[];
    for (final statsDoc in statsSnapshot.docs) {
      final match = all.where((corridor) => corridor.id == statsDoc.id);
      if (match.isNotEmpty) corridors.add(match.first);
    }
    return corridors;
  }

  @override
  Stream<CorridorStats?> watchStats(String corridorId) {
    return firestore
        .collection(FirestorePaths.corridorStats)
        .doc(corridorId)
        .snapshots()
        .map((doc) {
          //no stats yet means nobody reported this route
          if (!doc.exists) return null;
          final updated = doc.get('updatedAt') as Timestamp?;
          return CorridorStats(
            corridorId: corridorId,
            median: (doc.get('median') as num).toInt(),
            low: (doc.get('low') as num).toInt(),
            high: (doc.get('high') as num).toInt(),
            sampleSize: (doc.get('sampleSize') as num).toInt(),
            confidence: doc.get('confidence') as String,
            updatedAt: updated?.toDate() ?? DateTime.now(),
          );
        });
  }

  @override
  Future<List<Corridor>> popularCorridors() {
    return corridorsWithPrices(maxPopular);
  }

  @override
  Future<List<Corridor>> searchCorridors(String query) async {
    final text = query.trim().toLowerCase();

    //nothing typed, show the routes that have prices
    if (text.isEmpty) return corridorsWithPrices(maxRoutes);

    //typed something, find every route that has this area in it
    final all = await loadAllCorridors();
    return all.where((corridor) {
      return corridor.fromArea.toLowerCase().contains(text) ||
          corridor.toArea.toLowerCase().contains(text);
    }).toList();
  }
}
