//reads the areas from firestore. this is the real version of the zone list
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../domain/zone_finder.dart';
import 'zone_repository.dart';

class ZoneRepositoryImpl implements ZoneRepository {
  ZoneRepositoryImpl(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<List<Zone>> getZones() async {
    //get the whole zones collection, sorted by name
    final snapshot = await firestore
        .collection(FirestorePaths.zones)
        .orderBy('name')
        .get();

    //turn each document into a Zone. the id of the document is the zone id
    return [
      for (final doc in snapshot.docs)
        Zone(
          id: doc.id,
          name: doc.get('name') as String,
          latitude: (doc.get('latitude') as num).toDouble(),
          longitude: (doc.get('longitude') as num).toDouble(),
        ),
    ];
  }
}