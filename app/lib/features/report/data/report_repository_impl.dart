import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/new_report.dart';
import '../domain/entities/report.dart';
import '../domain/repositories/report_repository.dart';
import 'report_model.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({
    FirebaseFirestore? firestore,
    String? Function()? currentUid,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _currentUid =
           currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final FirebaseFirestore _firestore;

  /// Signed in passenger id, or null
  final String? Function() _currentUid;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(FirestorePaths.reports);

  String get _uid {
    final uid = _currentUid();
    if (uid == null) throw const AuthFailure('Sign in to report a fare');
    return uid;
  }

  @override
  Future<void> submit(NewReport report) {
    return _guard(
      () => _reports.add(ReportModel.toCreateMap(report, _uid)),
      denied: 'This report could not be saved. Check the route and price',
    );
  }

  /// Newest first, only the signed in passenger's reports
  @override
  Stream<List<Report>> watchMine() {
    final uid = _currentUid();
    if (uid == null) return Stream.value(const []);
    return _reports
        .where('passengerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              ReportModel.fromMap(doc.id, doc.data()),
          ],
        )
        .handleError((Object error) => throw _toFailure(error, ''));
  }

  @override
  Future<void> updatePendingPrice(String reportId, int price) {
    return _guard(
      () => _reports.doc(reportId).update({'price': price}),
      denied: 'This report is no longer pending, so it cannot be edited',
    );
  }

  @override
  Future<void> deletePending(String reportId) {
    return _guard(
      () => _reports.doc(reportId).delete(),
      denied: 'This report is no longer pending, so it cannot be deleted',
    );
  }

  Future<void> _guard(
    Future<Object?> Function() action, {
    required String denied,
  }) async {
    try {
      await action();
    } catch (error) {
      throw _toFailure(error, denied);
    }
  }

  /// Firebase errors to messages the screens can show
  Failure _toFailure(Object error, String denied) {
    if (error is Failure) return error;
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' when denied.isNotEmpty => FirestoreFailure(denied),
        'unavailable' => const NetworkFailure(),
        _ => const FirestoreFailure(),
      };
    }
    return const FirestoreFailure();
  }
}
