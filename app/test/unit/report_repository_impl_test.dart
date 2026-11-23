import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/features/report/data/report_repository_impl.dart';
import 'package:fairfare/features/report/domain/entities/new_report.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  ReportRepositoryImpl repo(String? uid) =>
      ReportRepositoryImpl(firestore: firestore, currentUid: () => uid);

  const newReport = NewReport(
    corridorId: 'alu-downtown',
    price: 1800,
    timeSegment: TimeSegment.evening,
    weather: Weather.clear,
  );

  Future<DocumentReference<Map<String, dynamic>>> addReport(
    String passengerId, {
    required DateTime createdAt,
    String status = 'pending',
    int price = 1000,
  }) {
    return firestore.collection('reports').add({
      'passengerId': passengerId,
      'corridorId': 'alu-downtown',
      'price': price,
      'timeSegment': 'morning',
      'weather': 'clear',
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    });
  }

  test('submit writes the fields the rules allow', () async {
    await repo('alice').submit(newReport);

    final docs = (await firestore.collection('reports').get()).docs;
    expect(docs, hasLength(1));
    final data = docs.single.data();
    expect(data.keys.toSet(), {
      'passengerId',
      'corridorId',
      'price',
      'timeSegment',
      'weather',
      'status',
      'createdAt',
    });
    expect(data['passengerId'], 'alice');
    expect(data['price'], 1800);
    expect(data['timeSegment'], 'evening');
    expect(data['status'], 'pending');
    expect(data['createdAt'], isA<Timestamp>());
  });

  test('signed out: submit is refused', () async {
    await expectLater(
      repo(null).submit(newReport),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('watchMine shows only my reports, newest first', () async {
    await addReport('alice', createdAt: DateTime(2026, 11, 20), price: 900);
    await addReport('alice', createdAt: DateTime(2026, 11, 21), price: 1100);
    await addReport('bob', createdAt: DateTime(2026, 11, 22), price: 5000);

    final reports = await repo('alice').watchMine().first;

    expect(reports.map((r) => r.price), [1100, 900]);
    expect(reports.every((r) => r.passengerId == 'alice'), isTrue);
  });

  test('signed out: watchMine is empty', () async {
    await addReport('alice', createdAt: DateTime(2026, 11, 20));
    expect(await repo(null).watchMine().first, isEmpty);
  });

  test('a status change from the server shows up live', () async {
    final doc = await addReport('alice', createdAt: DateTime(2026, 11, 20));
    final seen = <ReportStatus>[];
    final sub = repo('alice').watchMine().listen((reports) {
      if (reports.isNotEmpty) seen.add(reports.single.status);
    });

    await pumpEventQueue();
    await doc.update({'status': 'verified'});
    await pumpEventQueue();
    await sub.cancel();

    expect(seen, [ReportStatus.pending, ReportStatus.verified]);
  });

  test('editing a pending report changes only the price', () async {
    final doc = await addReport('alice', createdAt: DateTime(2026, 11, 20));

    await repo('alice').updatePendingPrice(doc.id, 1200);

    final data = (await doc.get()).data()!;
    expect(data['price'], 1200);
    expect(data['status'], 'pending');
  });

  test('deleting a pending report removes it', () async {
    final doc = await addReport('alice', createdAt: DateTime(2026, 11, 20));

    await repo('alice').deletePending(doc.id);

    expect((await doc.get()).exists, isFalse);
  });

  test('editing a report the rules refuse explains why', () async {
    // The fake does not run the rules, so stage the refusal
    final doc = await addReport(
      'alice',
      createdAt: DateTime(2026, 11, 20),
      status: 'verified',
    );
    whenCalling(Invocation.method(#update, null))
        .on(doc)
        .thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );

    await expectLater(
      repo('alice').updatePendingPrice(doc.id, 1200),
      throwsA(
        isA<FirestoreFailure>().having(
          (f) => f.message,
          'message',
          contains('no longer pending'),
        ),
      ),
    );
  });

  test('a network error is a NetworkFailure', () async {
    final doc = await addReport('alice', createdAt: DateTime(2026, 11, 20));
    whenCalling(Invocation.method(#delete, null))
        .on(doc)
        .thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        );

    await expectLater(
      repo('alice').deletePending(doc.id),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
