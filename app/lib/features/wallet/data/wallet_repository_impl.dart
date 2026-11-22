// Firestore-backed WalletRepository (D4).
//
// Reads are owner only (B2 rules): wallets/{uid}, and walletEntries and
// cashOutRequests filtered to the passenger's own id. The only write the app
// makes is a pending cash out request, with exactly the fields the rules
// allow. Balances, reward entries and request statuses are written by the
// server (D5 reward engine), so the screen updates live when they change.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/failures.dart';
import '../../report/domain/entities/report_enums.dart';
import '../domain/entities/cash_out_request.dart';
import '../domain/entities/wallet.dart';
import '../domain/entities/wallet_entry.dart';
import '../domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  /// [uid] is the signed-in passenger, or null when nobody is signed in.
  WalletRepositoryImpl(this._firestore, {required this.uid, this.clock});

  final FirebaseFirestore _firestore;
  final String? uid;

  /// Overrides "now" in tests. Used for a request whose server timestamp has
  /// not come back yet.
  final DateTime Function()? clock;

  @override
  Stream<Wallet> watchWallet() {
    final uid = this.uid;
    if (uid == null) return Stream.error(_signedOut);
    return _firestore
        .collection(FirestorePaths.wallets)
        .doc(uid)
        .snapshots()
        .map((snap) => walletFromFirestore(snap.data()))
        .handleError(_rethrowAsFailure);
  }

  @override
  Stream<List<WalletEntry>> watchEntries() {
    final uid = this.uid;
    if (uid == null) return Stream.error(_signedOut);
    // The rules only allow a list filtered to the passenger's own id.
    return _ownNewestFirst(FirestorePaths.walletEntries, uid)
        .map(
          (snap) => [
            for (final doc in snap.docs)
              walletEntryFromFirestore(doc.id, doc.data(), now: _now()),
          ],
        )
        .handleError(_rethrowAsFailure);
  }

  @override
  Stream<List<CashOutRequest>> watchCashOutRequests() {
    final uid = this.uid;
    if (uid == null) return Stream.error(_signedOut);
    return _ownNewestFirst(FirestorePaths.cashOutRequests, uid)
        .map(
          (snap) => [
            for (final doc in snap.docs)
              cashOutRequestFromFirestore(doc.id, doc.data(), now: _now()),
          ],
        )
        .handleError(_rethrowAsFailure);
  }

  @override
  Future<void> requestCashOut(int amount, String method) async {
    final uid = this.uid;
    if (uid == null) throw const AuthFailure('Sign in to cash out');
    try {
      // createdAt must equal request.time in the rules, so it is always the
      // server timestamp, never the phone's clock.
      await _firestore.collection(FirestorePaths.cashOutRequests).add({
        'passengerId': uid,
        'amount': amount,
        'method': method,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stack) {
      if (error.code == 'permission-denied') {
        // The form already checks the amount, so a refusal means the
        // finalized balance changed (or the wallet does not exist yet).
        Error.throwWithStackTrace(
          const FirestoreFailure(
            'You can only cash out points that are already finalized',
          ),
          stack,
        );
      }
      Error.throwWithStackTrace(_failure(error), stack);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _ownNewestFirst(
    String collection,
    String uid,
  ) => _firestore
      .collection(collection)
      .where('passengerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots();

  DateTime _now() => (clock ?? DateTime.now)();

  static const _signedOut = AuthFailure('Sign in to see your wallet');

  static Never _rethrowAsFailure(Object error, StackTrace stack) =>
      Error.throwWithStackTrace(_failure(error), stack);

  static Object _failure(Object error) {
    if (error is! FirebaseException) return error;
    return switch (error.code) {
      'unavailable' || 'network-request-failed' => const NetworkFailure(),
      'permission-denied' => const FirestoreFailure(
        'You do not have access to this wallet',
      ),
      _ => const FirestoreFailure('Could not load your wallet. Try again'),
    };
  }
}

/// Maps wallets/{uid} to a [Wallet]. A passenger with no reward yet has no
/// wallet document, which shows as zero points.
Wallet walletFromFirestore(Map<String, dynamic>? data) => Wallet(
  pendingBalance: _int(data?['pendingBalance']),
  finalizedBalance: _int(data?['finalizedBalance']),
);

/// Maps a walletEntries/{reportId} document to a [WalletEntry].
WalletEntry walletEntryFromFirestore(
  String id,
  Map<String, dynamic> data, {
  required DateTime now,
}) => WalletEntry(
  id: id,
  reportId: data['reportId'] as String?,
  amount: _int(data['amount']),
  state: data['state'] == 'finalized' ? 'finalized' : 'pending',
  createdAt: _date(data['createdAt']) ?? now,
);

/// Maps a cashOutRequests/{id} document to a [CashOutRequest]. createdAt is
/// null for a moment after a request is sent, until the server timestamp
/// comes back, so it falls back to [now].
CashOutRequest cashOutRequestFromFirestore(
  String id,
  Map<String, dynamic> data, {
  required DateTime now,
}) => CashOutRequest(
  id: id,
  amount: _int(data['amount']),
  method: data['method'] is String ? data['method'] as String : '',
  status: switch (data['status']) {
    'paid' => CashOutStatus.paid,
    'rejected' => CashOutStatus.rejected,
    _ => CashOutStatus.pending,
  },
  createdAt: _date(data['createdAt']) ?? now,
);

int _int(Object? value) => value is num ? value.toInt() : 0;

DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;
