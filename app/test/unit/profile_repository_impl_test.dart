import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/features/profile/data/profile_repository_impl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  Future<void> registerPassenger(String uid) =>
      firestore.collection('passengers').doc(uid).set({
        'displayName': 'Aline',
        'email': 'aline@example.com',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
      });

  test(
    'a newly registered passenger reads with zero score and no badges',
    () async {
      await registerPassenger('p1');
      final me = await ProfileRepositoryImpl(
        firestore,
        uid: 'p1',
      ).watchMe().first;
      expect(me.id, 'p1');
      expect(me.displayName, 'Aline');
      expect(me.email, 'aline@example.com');
      expect(me.trustScore, 0);
      expect(me.streak, 0);
      expect(me.badges, isEmpty);
      expect(me.lastReportDate, isNull);
    },
  );

  test('server-written trust fields are read', () async {
    await registerPassenger('p1');
    await firestore.collection('passengers').doc('p1').update({
      'trustScore': 42,
      'streak': 3,
      'badges': ['Corridor Pioneer'],
      'verifiedCount': 4,
      'lastReportDate': Timestamp.fromDate(DateTime(2026, 11, 18)),
    });
    final me = await ProfileRepositoryImpl(
      firestore,
      uid: 'p1',
    ).watchMe().first;
    expect(me.trustScore, 42);
    expect(me.streak, 3);
    expect(me.badges, ['Corridor Pioneer']);
    expect(me.verifiedCount, 4);
    expect(me.lastReportDate, DateTime(2026, 11, 18));
  });

  test('waits for the passenger document instead of failing', () async {
    final first = ProfileRepositoryImpl(firestore, uid: 'p1').watchMe().first;
    await registerPassenger('p1');
    expect((await first).displayName, 'Aline');
  });

  test('updateDisplayName writes only the name', () async {
    await registerPassenger('p1');
    await ProfileRepositoryImpl(
      firestore,
      uid: 'p1',
    ).updateDisplayName('Aline U.');
    final doc = await firestore.collection('passengers').doc('p1').get();
    expect(doc.data()!['displayName'], 'Aline U.');
    expect(doc.data()!['email'], 'aline@example.com');
  });

  test(
    'no avatar until the passenger picks one; unknown ids are ignored',
    () async {
      await registerPassenger('p1');
      final repo = ProfileRepositoryImpl(firestore, uid: 'p1');
      expect((await repo.watchMe().first).avatar, isNull);

      await firestore.collection('passengers').doc('p1').update({
        'avatar': 'zz',
      });
      expect((await repo.watchMe().first).avatar, isNull);
    },
  );

  test('updateAvatar saves a preset id and nothing else', () async {
    await registerPassenger('p1');
    final repo = ProfileRepositoryImpl(firestore, uid: 'p1');
    await repo.updateAvatar('w03');
    final doc = await firestore.collection('passengers').doc('p1').get();
    expect(doc.data()!['avatar'], 'w03');
    expect(doc.data()!['displayName'], 'Aline');
    expect((await repo.watchMe().first).avatar, 'w03');

    await expectLater(
      repo.updateAvatar('w99'),
      throwsA(isA<FirestoreFailure>()),
    );
    await expectLater(
      ProfileRepositoryImpl(firestore, uid: null).updateAvatar('w01'),
      throwsA(isA<AuthFailure>()),
    );
  });

  test(
    'a refused avatar save says so, not that the profile is off limits',
    () async {
      await registerPassenger('p1');
      whenCalling(Invocation.method(#update, null))
          .on(firestore.collection('passengers').doc('p1'))
          .thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
          );
      await expectLater(
        ProfileRepositoryImpl(firestore, uid: 'p1').updateAvatar('w03'),
        throwsA(
          isA<FirestoreFailure>().having(
            (f) => f.message,
            'message',
            'Could not save your avatar. Please try again later',
          ),
        ),
      );
    },
  );

  test('signed out: profile errors with an AuthFailure', () async {
    final repo = ProfileRepositoryImpl(firestore, uid: null);
    expect(repo.watchMe().first, throwsA(isA<AuthFailure>()));
    expect(repo.updateDisplayName('X'), throwsA(isA<AuthFailure>()));
  });

  test('leaderboard is the top 10 by trust score, highest first', () async {
    for (var i = 0; i < 12; i++) {
      await firestore.collection('leaderboard').doc('p$i').set({
        'displayName': 'P$i',
        'trustScore': i * 5,
      });
    }
    final rows = await ProfileRepositoryImpl(
      firestore,
      uid: 'p1',
    ).watchLeaderboard().first;
    expect(rows, hasLength(10));
    expect(rows.first.id, 'p11');
    expect(rows.first.trustScore, 55);
    expect(rows.last.trustScore, 10);
  });
}
