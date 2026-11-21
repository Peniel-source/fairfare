import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/features/auth/data/firebase_auth_repository.dart';
import 'package:fairfare/features/auth/domain/entities/auth_user.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class _User extends Fake implements User {
  _User(this.auth);
  final _Auth auth;
  @override
  final String uid = 'passenger-1';
  @override
  String get email => 'passenger@example.com';
  @override
  String? displayName;
  @override
  bool emailVerified = false;
  bool verifiedOnServer = false;
  bool deleted = false;
  bool tokenRefreshed = false;
  int emailsSent = 0;
  FirebaseAuthException? emailFailure;
  Completer<void>? profilePending;

  @override
  Future<void> updateDisplayName(String? name) async {
    await profilePending?.future;
    displayName = name;
    auth.events.add(this);
  }

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? settings]) async {
    if (emailFailure != null) throw emailFailure!;
    emailsSent++;
  }

  @override
  Future<void> reload() async {
    emailVerified = verifiedOnServer;
    auth.events.add(this);
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    tokenRefreshed = forceRefresh;
    return 'test-token';
  }

  @override
  Future<void> delete() async {
    deleted = true;
    auth.currentUser = null;
    auth.events.add(null);
  }
}

class _Credential extends Fake implements UserCredential {
  _Credential(this.user);
  @override
  final User user;
}

class _Auth extends Fake implements FirebaseAuth {
  final events = StreamController<User?>.broadcast();
  late final passenger = _User(this);
  @override
  User? currentUser;
  FirebaseAuthException? failure;
  String? emailUsed;
  String? passwordUsed;

  @override
  Stream<User?> userChanges() async* {
    yield currentUser;
    yield* events.stream;
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (failure != null) throw failure!;
    emailUsed = email;
    passwordUsed = password;
    currentUser = passenger;
    events.add(passenger);
    return _Credential(passenger);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => createUserWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    if (failure != null) throw failure!;
    emailUsed = email;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    events.add(null);
  }
}

void main() {
  late _Auth auth;
  late FakeFirebaseFirestore store;
  late FirebaseAuthRepository repository;

  setUp(() {
    auth = _Auth();
    store = FakeFirebaseFirestore();
    repository = FirebaseAuthRepository(auth, store);
  });

  tearDown(() async {
    await auth.events.close();
  });

  test(
    'registration writes only allowed profile fields and a server timestamp',
    () async {
      await repository.registerWithEmail(
        ' passenger@example.com ',
        ' pass1234 ',
        ' Menes ',
      );
      expect(auth.emailUsed, 'passenger@example.com');
      expect(auth.passwordUsed, ' pass1234 ');
      final profile =
          (await store.collection('passengers').doc(auth.passenger.uid).get())
              .data()!;
      expect(
        profile.keys,
        unorderedEquals(['displayName', 'email', 'createdAt']),
      );
      expect(profile['displayName'], 'Menes');
      expect(profile['email'], auth.passenger.email);
      expect(profile['createdAt'], isA<Timestamp>());
      expect(auth.passenger.displayName, 'Menes');
      expect(auth.passenger.emailsSent, 1);
    },
  );

  test(
    'registration holds auth redirects until profile creation finishes',
    () async {
      final users = <AuthUser?>[];
      final listener = repository.authStateChanges().listen(users.add);
      addTearDown(listener.cancel);
      await Future<void>.delayed(Duration.zero);
      auth.passenger.profilePending = Completer<void>();
      final registration = repository.registerWithEmail(
        'passenger@example.com',
        'pass1234',
        'Menes',
      );
      await Future<void>.delayed(Duration.zero);
      expect(users.every((user) => user == null), isTrue);
      expect(auth.passenger.emailsSent, 0);
      auth.passenger.profilePending!.complete();
      await registration;
      await Future<void>.delayed(Duration.zero);
      expect(users.last?.id, auth.passenger.uid);
      expect(users.last?.emailVerified, isFalse);
    },
  );

  test('failed profile creation removes the incomplete auth account', () async {
    store = FakeFirebaseFirestore(
      securityRules: 'service cloud.firestore { match /databases/{database}/documents { match /{document=**} { allow read, write: if false; } } }',
    );
    repository = FirebaseAuthRepository(auth, store);
    await expectLater(
      repository.registerWithEmail(
        'passenger@example.com',
        'pass1234',
        'Menes',
      ),
      throwsA(isA<Exception>()),
    );
    expect(auth.passenger.deleted, isTrue);
    expect(auth.currentUser, isNull);
    expect(auth.passenger.emailsSent, 0);
  });

  test(
    'email delivery failure keeps the account and supports resend',
    () async {
      auth.passenger.emailFailure = FirebaseAuthException(
        code: 'too-many-requests',
      );
      await expectLater(
        repository.registerWithEmail(
          'passenger@example.com',
          'pass1234',
          'Menes',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (error) => error.message,
            'message',
            contains('Resend email'),
          ),
        ),
      );
      expect(auth.currentUser, isNotNull);
      expect(auth.passenger.deleted, isFalse);
      auth.passenger.emailFailure = null;
      await repository.sendEmailVerification();
      expect(auth.passenger.emailsSent, 1);
    },
  );

  test(
    'restored sessions and verification reloads reach the auth stream',
    () async {
      auth.currentUser = auth.passenger;
      final users = <AuthUser?>[];
      final listener = repository.authStateChanges().listen(users.add);
      addTearDown(listener.cancel);
      await Future<void>.delayed(Duration.zero);
      expect(users.last?.id, auth.passenger.uid);
      auth.passenger.verifiedOnServer = true;
      await repository.reloadUser();
      await Future<void>.delayed(Duration.zero);
      expect(users.last?.emailVerified, isTrue);
      expect(auth.passenger.tokenRefreshed, isTrue);
      await repository.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(users.last, isNull);
    },
  );

  final failures = <String, Matcher>{
    'wrong-password': isA<WrongPasswordFailure>(),
    'user-not-found': isA<UserNotFoundFailure>(),
    'too-many-requests': isA<TooManyAttemptsFailure>(),
    'network-request-failed': isA<NetworkFailure>(),
    'permission-denied': isA<FirestoreFailure>(),
    'invalid-email': isA<InvalidEmailFailure>(),
    'email-already-in-use': isA<EmailInUseFailure>(),
    'weak-password': isA<WeakPasswordFailure>(),
    'user-disabled': isA<AuthFailure>(),
    'invalid-credential': isA<AuthFailure>().having(
      (e) => e.message,
      'message',
      'Email or password is incorrect',
    ),
  };
  for (final failure in failures.entries) {
    test('${failure.key} maps to an understandable failure', () async {
      auth.failure = FirebaseAuthException(code: failure.key);
      await expectLater(
        repository.signInWithEmail('passenger@example.com', 'pass1234'),
        throwsA(failure.value),
      );
    });
  }

  test(
    'reset does not disclose missing accounts and trims the email',
    () async {
      await repository.sendPasswordReset(' passenger@example.com ');
      expect(auth.emailUsed, 'passenger@example.com');
      auth.failure = FirebaseAuthException(code: 'user-not-found');
      await repository.sendPasswordReset('missing@example.com');
      auth.failure = FirebaseAuthException(code: 'network-request-failed');
      await expectLater(
        repository.sendPasswordReset('passenger@example.com'),
        throwsA(isA<NetworkFailure>()),
      );
    },
  );
}
