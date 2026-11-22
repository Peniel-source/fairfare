// Firestore-backed SubscriptionRepository (E2).
//
// submitReference creates subscriptions/{reference} with exactly the fields
// the rules allow: passengerId, reference, amount and status 'pending'. The
// reference is the document id, so a reused reference (by anyone, even one
// that was rejected) is refused by the rules. Only the server (E3) sets
// status 'active' with startsAt and endsAt, or 'rejected'.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/failures.dart';
import '../../report/domain/entities/report_enums.dart';
import '../domain/entities/subscription.dart';
import '../domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  /// [uid] is the signed-in passenger, or null when nobody is signed in.
  SubscriptionRepositoryImpl(this._firestore, {required this.uid, this.clock});

  final FirebaseFirestore _firestore;
  final String? uid;

  /// Overrides "now" in tests; decides whether an active Pass has expired.
  final DateTime Function()? clock;

  CollectionReference<Map<String, dynamic>> get _subscriptions =>
      _firestore.collection(FirestorePaths.subscriptions);

  @override
  Stream<Subscription?> watchMine() {
    final uid = this.uid;
    if (uid == null) {
      return Stream.error(const AuthFailure('Sign in to see your Pass'));
    }
    // The rules only allow a list filtered to the passenger's own id.
    return _subscriptions
        .where('passengerId', isEqualTo: uid)
        .snapshots()
        .map(
          (snap) => currentSubscription([
            for (final doc in snap.docs)
              subscriptionFromFirestore(doc.id, doc.data()),
          ], now: (clock ?? DateTime.now)()),
        )
        .handleError(
          (Object error, StackTrace stack) =>
              Error.throwWithStackTrace(_failure(error), stack),
        );
  }

  @override
  Future<void> submitReference(String reference, int amount) async {
    final uid = this.uid;
    if (uid == null) throw const AuthFailure('Sign in to buy a Pass');
    try {
      // set() on an id that already exists counts as an update, which the
      // rules never allow, so a duplicate fails with permission-denied.
      await _subscriptions.doc(reference).set({
        'passengerId': uid,
        'reference': reference,
        'amount': amount,
        'status': 'pending',
      });
    } on FirebaseException catch (error, stack) {
      if (error.code == 'permission-denied' || error.code == 'already-exists') {
        // The form validates the reference and the amount is the fixed Pass
        // price, so a refusal here means the reference was already used.
        Error.throwWithStackTrace(const DuplicateReferenceFailure(), stack);
      }
      Error.throwWithStackTrace(_failure(error), stack);
    }
  }

  Object _failure(Object error) {
    if (error is! FirebaseException) return error;
    return switch (error.code) {
      'unavailable' || 'network-request-failed' => const NetworkFailure(),
      'permission-denied' => const FirestoreFailure(
        'You do not have access to this Pass',
      ),
      _ => const FirestoreFailure('Could not load your Pass. Try again'),
    };
  }
}

/// Maps a subscriptions/{reference} document to a [Subscription].
Subscription subscriptionFromFirestore(String id, Map<String, dynamic> data) {
  final amount = data['amount'];
  return Subscription(
    reference: id,
    amount: amount is num ? amount.toInt() : 0,
    status: _status(data['status']),
    startsAt: _date(data['startsAt']),
    endsAt: _date(data['endsAt']),
  );
}

/// The one subscription the Pass screen shows, out of all of a passenger's:
/// an active Pass that has not ended (the latest one), else one waiting for
/// approval, else a rejected one so the passenger sees why and can retry.
/// Expired Passes count as no Pass, so the passenger can buy a new one.
Subscription? currentSubscription(
  List<Subscription> all, {
  required DateTime now,
}) {
  final active =
      all
          .where(
            (s) =>
                s.status == SubscriptionStatus.active &&
                s.endsAt != null &&
                s.endsAt!.isAfter(now),
          )
          .toList()
        ..sort((a, b) => b.endsAt!.compareTo(a.endsAt!));
  if (active.isNotEmpty) return active.first;

  for (final status in [
    SubscriptionStatus.pending,
    SubscriptionStatus.rejected,
  ]) {
    final match = all.where((s) => s.status == status);
    if (match.isNotEmpty) return match.first;
  }
  return null;
}

SubscriptionStatus _status(Object? value) => switch (value) {
  'active' => SubscriptionStatus.active,
  'rejected' => SubscriptionStatus.rejected,
  _ => SubscriptionStatus.pending,
};

DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;
