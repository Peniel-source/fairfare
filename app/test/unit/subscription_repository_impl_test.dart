import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/features/pass/data/subscription_repository_impl.dart';
import 'package:fairfare/features/pass/domain/entities/subscription.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 20, 12);
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  SubscriptionRepositoryImpl repo(String? uid) =>
      SubscriptionRepositoryImpl(firestore, uid: uid, clock: () => now);

  test('submit creates exactly the fields the rules allow', () async {
    await repo('alice').submitReference('7654321', 2000);
    final doc = await firestore
        .collection('subscriptions')
        .doc('7654321')
        .get();
    expect(doc.data(), {
      'passengerId': 'alice',
      'reference': '7654321',
      'amount': 2000,
      'status': 'pending',
    });
  });

  test('shows pending, then active once the server approves', () async {
    final updates = repo('alice').watchMine();
    final seen = <SubscriptionStatus?>[];
    final sub = updates.listen((s) => seen.add(s?.status));

    await pumpEventQueue();
    await repo('alice').submitReference('7654321', 2000);
    await pumpEventQueue();
    // What E3 writes on approval.
    await firestore.collection('subscriptions').doc('7654321').update({
      'status': 'active',
      'startsAt': Timestamp.fromDate(now),
      'endsAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
    });
    await pumpEventQueue();
    await sub.cancel();

    expect(seen, [null, SubscriptionStatus.pending, SubscriptionStatus.active]);
  });

  test('reads only the signed-in passenger\'s own subscriptions', () async {
    await repo('bob').submitReference('5555555', 2000);
    expect(await repo('alice').watchMine().first, isNull);
  });

  test('a reused reference is a DuplicateReferenceFailure', () async {
    // The real rules refuse a second write to an existing reference with
    // permission-denied; the fake does not run our rules, so stage that.
    final existing = firestore.collection('subscriptions').doc('7654321');
    whenCalling(Invocation.method(#set, null))
        .on(existing)
        .thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
    await expectLater(
      repo('bob').submitReference('7654321', 2000),
      throwsA(isA<DuplicateReferenceFailure>()),
    );
  });

  test('a network error is not mistaken for a duplicate', () async {
    final doc = firestore.collection('subscriptions').doc('7654321');
    whenCalling(Invocation.method(#set, null))
        .on(doc)
        .thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        );
    await expectLater(
      repo('alice').submitReference('7654321', 2000),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('signed out: no Pass can be read or bought', () async {
    expect(repo(null).watchMine().first, throwsA(isA<AuthFailure>()));
    expect(
      repo(null).submitReference('7654321', 2000),
      throwsA(isA<AuthFailure>()),
    );
  });

  group('currentSubscription', () {
    Subscription sub(
      String ref,
      SubscriptionStatus status, {
      DateTime? endsAt,
    }) => Subscription(
      reference: ref,
      amount: 2000,
      status: status,
      endsAt: endsAt,
    );

    test('prefers a running Pass over pending and rejected', () {
      final pick = currentSubscription([
        sub('R1', SubscriptionStatus.rejected),
        sub('P1', SubscriptionStatus.pending),
        sub(
          'A1',
          SubscriptionStatus.active,
          endsAt: now.add(const Duration(days: 3)),
        ),
      ], now: now);
      expect(pick!.reference, 'A1');
    });

    test('pending beats rejected; an expired Pass counts as none', () {
      final expired = sub(
        'A0',
        SubscriptionStatus.active,
        endsAt: now.subtract(const Duration(days: 1)),
      );
      expect(
        currentSubscription([
          expired,
          sub('R1', SubscriptionStatus.rejected),
          sub('P1', SubscriptionStatus.pending),
        ], now: now)!.reference,
        'P1',
      );
      expect(currentSubscription([expired], now: now), isNull);
      expect(currentSubscription([], now: now), isNull);
    });
  });
}
