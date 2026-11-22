// Firestore-backed ProfileRepository (E4).
//
// Reads passengers/{uid}, written at registration by B4 (displayName, email,
// createdAt). trustScore, streak, badges, verifiedCount and lastReportDate are
// added later by the server (E5), so a new passenger's document has none of
// them and they default to 0 / empty. The leaderboard comes from the public
// leaderboard/{uid} projection, also written only by the server.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/leaderboard_entry.dart';
import '../domain/entities/passenger.dart';
import '../domain/repositories/profile_repository.dart';

/// How many leaderboard rows are fetched from Firestore.
const kLeaderboardQueryLimit = 10;

class ProfileRepositoryImpl implements ProfileRepository {
  /// [uid] is the signed-in passenger, or null when nobody is signed in.
  ProfileRepositoryImpl(this._firestore, {required this.uid});

  final FirebaseFirestore _firestore;
  final String? uid;

  DocumentReference<Map<String, dynamic>> _me(String uid) =>
      _firestore.collection(FirestorePaths.passengers).doc(uid);

  @override
  Stream<Passenger> watchMe() {
    final uid = this.uid;
    if (uid == null) {
      return Stream.error(const AuthFailure('Sign in to see your profile'));
    }
    return _me(uid)
        .snapshots()
        // Right after registration the document may not exist yet; wait for
        // it instead of showing an error.
        .where((snap) => snap.exists)
        .map((snap) => passengerFromFirestore(snap.id, snap.data()!))
        .handleError(
          (Object error, StackTrace stack) =>
              Error.throwWithStackTrace(_failure(error), stack),
        );
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final uid = this.uid;
    if (uid == null) throw const AuthFailure('Sign in to change your name');
    try {
      // The rules allow passengers to change displayName only.
      await _me(uid).update({'displayName': name});
    } catch (error, stack) {
      Error.throwWithStackTrace(_failure(error), stack);
    }
  }

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() {
    return _firestore
        .collection(FirestorePaths.leaderboard)
        .orderBy('trustScore', descending: true)
        .limit(kLeaderboardQueryLimit)
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              LeaderboardEntry(
                id: doc.id,
                displayName: _string(doc.data()['displayName']),
                trustScore: _int(doc.data()['trustScore']),
              ),
          ],
        )
        .handleError(
          (Object error, StackTrace stack) =>
              Error.throwWithStackTrace(_failure(error), stack),
        );
  }

  Object _failure(Object error) {
    if (error is! FirebaseException) return error;
    return switch (error.code) {
      'unavailable' || 'network-request-failed' => const NetworkFailure(),
      'permission-denied' => const FirestoreFailure(
        'You do not have access to this profile',
      ),
      'not-found' => const FirestoreFailure('Your profile was not found'),
      _ => const FirestoreFailure('Could not load your profile. Try again'),
    };
  }
}

/// Maps a passengers/{uid} document to a [Passenger]. Server-owned fields
/// that are missing or malformed fall back to a brand new passenger's values.
Passenger passengerFromFirestore(String id, Map<String, dynamic> data) {
  final badges = data['badges'];
  final lastReport = data['lastReportDate'];
  return Passenger(
    id: id,
    displayName: _string(data['displayName']),
    email: _string(data['email']),
    trustScore: _int(data['trustScore']),
    streak: _int(data['streak']),
    badges: badges is List ? badges.whereType<String>().toList() : const [],
    verifiedCount: _int(data['verifiedCount']),
    lastReportDate: lastReport is Timestamp ? lastReport.toDate() : null,
  );
}

String _string(Object? value) => value is String ? value : '';

int _int(Object? value) => value is num ? value.toInt() : 0;
