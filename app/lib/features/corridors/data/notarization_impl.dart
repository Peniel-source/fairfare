//reads the newest receipt the server notary saved in firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairfare/core/constants/firestore_paths.dart';

import 'notarization_repository.dart';

class NotarizationRepositoryImpl implements NotarizationRepository {
  NotarizationRepositoryImpl(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<Notarization?> latest() async {
    //newest first, only need one
    final snapshot = await firestore
        .collection(FirestorePaths.notarizations)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();
    return Notarization(
      date: (data['date'] ?? '').toString(),
      hash: (data['hash'] ?? '').toString(),
      txHash: (data['txHash'] ?? '').toString(),
      network: (data['network'] ?? 'preview').toString(),
    );
  }
}