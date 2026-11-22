// D4: the Firestore wallet repository, on an in-memory Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';
import 'package:fairfare/features/wallet/data/wallet_repository_impl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 22, 9);
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  WalletRepositoryImpl repo(String? uid) =>
      WalletRepositoryImpl(firestore, uid: uid, clock: () => now);

  Timestamp at(int day) => Timestamp.fromDate(DateTime(2026, 11, day));

  test('a passenger with no wallet document has zero points', () async {
    final wallet = await repo('alice').watchWallet().first;
    expect(wallet.pendingBalance, 0);
    expect(wallet.finalizedBalance, 0);
  });

  test('balances come from wallets/{uid}', () async {
    await firestore.collection('wallets').doc('alice').set({
      'pendingBalance': 52,
      'finalizedBalance': 300,
      'updatedAt': at(20),
    });
    final wallet = await repo('alice').watchWallet().first;
    expect(wallet.pendingBalance, 52);
    expect(wallet.finalizedBalance, 300);
  });

  test('the wallet updates live when the server finalizes a reward', () async {
    final doc = firestore.collection('wallets').doc('alice');
    await doc.set({'pendingBalance': 52, 'finalizedBalance': 0});
    final balances = repo('alice')
        .watchWallet()
        .map((w) => (w.pendingBalance, w.finalizedBalance));
    final seen = expectLater(balances, emitsInOrder([(52, 0), (0, 52)]));
    await Future<void>.delayed(Duration.zero);
    await doc.update({'pendingBalance': 0, 'finalizedBalance': 52});
    await seen;
  });

  test('reward history is the passenger\'s own, newest first', () async {
    final entries = firestore.collection('walletEntries');
    await entries.doc('report-1').set({
      'passengerId': 'alice',
      'reportId': 'report-1',
      'amount': 52,
      'state': 'finalized',
      'createdAt': at(18),
    });
    await entries.doc('report-2').set({
      'passengerId': 'alice',
      'reportId': 'report-2',
      'amount': 17,
      'state': 'pending',
      'createdAt': at(21),
    });
    await entries.doc('report-3').set({
      'passengerId': 'bob',
      'reportId': 'report-3',
      'amount': 99,
      'state': 'pending',
      'createdAt': at(22),
    });

    final list = await repo('alice').watchEntries().first;

    expect(list.map((e) => e.id), ['report-2', 'report-1']);
    expect(list.first.amount, 17);
    expect(list.first.state, 'pending');
    expect(list.last.state, 'finalized');
    expect(list.last.createdAt, DateTime(2026, 11, 18));
  });

  test('cash out writes exactly the fields the rules allow', () async {
    await repo('alice').requestCashOut(200, 'MTN MoMo');

    final docs = (await firestore.collection('cashOutRequests').get()).docs;
    expect(docs, hasLength(1));
    final data = docs.single.data();
    expect(
      data.keys,
      unorderedEquals([
        'passengerId',
        'amount',
        'method',
        'status',
        'createdAt',
      ]),
    );
    expect(data['passengerId'], 'alice');
    expect(data['amount'], 200);
    expect(data['method'], 'MTN MoMo');
    expect(data['status'], 'pending');
    expect(data['createdAt'], isA<Timestamp>());
  });

  test('cash out requests show newest first with their status', () async {
    final requests = firestore.collection('cashOutRequests');
    await requests.add({
      'passengerId': 'alice',
      'amount': 100,
      'method': 'Airtel Money',
      'status': 'paid',
      'createdAt': at(10),
    });
    await requests.add({
      'passengerId': 'alice',
      'amount': 50,
      'method': 'MTN MoMo',
      'status': 'rejected',
      'createdAt': at(12),
    });
    await requests.add({
      'passengerId': 'bob',
      'amount': 70,
      'method': 'MTN MoMo',
      'status': 'pending',
      'createdAt': at(13),
    });

    final list = await repo('alice').watchCashOutRequests().first;

    expect(list.map((r) => r.amount), [50, 100]);
    expect(list.map((r) => r.status), [
      CashOutStatus.rejected,
      CashOutStatus.paid,
    ]);
  });

  group('mappers', () {
    test('unknown or missing values fall back safely', () {
      final request = cashOutRequestFromFirestore('r1', {
        'amount': 10.0,
        'status': 'something-new',
      }, now: now);
      expect(request.amount, 10);
      expect(request.method, '');
      expect(request.status, CashOutStatus.pending);
      // A request whose server timestamp has not come back yet.
      expect(request.createdAt, now);

      final entry = walletEntryFromFirestore('e1', {'state': 'odd'}, now: now);
      expect(entry.state, 'pending');
      expect(entry.amount, 0);
      expect(entry.reportId, isNull);

      final wallet = walletFromFirestore({'pendingBalance': 'not a number'});
      expect(wallet.pendingBalance, 0);
    });
  });

  test('signed out: nothing can be read or requested', () async {
    expect(repo(null).watchWallet().first, throwsA(isA<AuthFailure>()));
    expect(repo(null).watchEntries().first, throwsA(isA<AuthFailure>()));
    expect(
      repo(null).watchCashOutRequests().first,
      throwsA(isA<AuthFailure>()),
    );
    await expectLater(
      repo(null).requestCashOut(10, 'MTN MoMo'),
      throwsA(isA<AuthFailure>()),
    );
  });
}
