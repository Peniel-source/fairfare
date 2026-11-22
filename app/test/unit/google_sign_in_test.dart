// D2: Google sign in and sign out in FirebaseAuthRepository.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/features/auth/data/firebase_auth_repository.dart';
import 'package:fairfare/features/auth/domain/entities/auth_user.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

class _UserInfo extends Fake implements UserInfo {
  _UserInfo(this.providerId);
  @override
  final String providerId;
}

class _User extends Fake implements User {
  _User({
    this.email = 'passenger@gmail.com',
    this.providers = const ['google.com'],
  });
  @override
  final String uid = 'google-passenger-1';
  @override
  final String? email;
  @override
  String? get displayName => '  Aline   Uwase ';
  final List<String> providers;
  @override
  bool get emailVerified => true;
  @override
  List<UserInfo> get providerData => [for (final p in providers) _UserInfo(p)];
}

class _Credential extends Fake implements UserCredential {
  _Credential(this.user);
  @override
  final User user;
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.googleUser);
  final User googleUser;
  final events = StreamController<User?>.broadcast();
  @override
  User? currentUser;
  FirebaseAuthException? failure;
  AuthCredential? credentialUsed;
  int signOuts = 0;

  @override
  Stream<User?> userChanges() async* {
    yield currentUser;
    yield* events.stream;
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    if (failure != null) throw failure!;
    credentialUsed = credential;
    currentUser = googleUser;
    events.add(googleUser);
    return _Credential(googleUser);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    currentUser = null;
    events.add(null);
  }
}

class _Tokens extends Fake implements GoogleSignInAuthentication {
  @override
  String? get idToken => 'google-id-token';
  @override
  String? get accessToken => 'google-access-token';
}

class _Account extends Fake implements GoogleSignInAccount {
  @override
  Future<GoogleSignInAuthentication> get authentication async => _Tokens();
}

class _Google extends Fake implements GoogleSignIn {
  bool cancel = false;
  PlatformException? failure;
  int signOuts = 0;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (failure != null) throw failure!;
    return cancel ? null : _Account();
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOuts++;
    return null;
  }
}

void main() {
  late FakeFirebaseFirestore store;
  late _Google google;

  setUp(() {
    store = FakeFirebaseFirestore();
    google = _Google();
  });

  ({_Auth auth, FirebaseAuthRepository repository}) build([_User? user]) {
    final auth = _Auth(user ?? _User());
    addTearDown(auth.events.close);
    return (
      auth: auth,
      repository: FirebaseAuthRepository(auth, store, googleSignIn: google),
    );
  }

  Future<Map<String, dynamic>?> profile() async =>
      (await store.collection('passengers').doc('google-passenger-1').get())
          .data();

  test(
    'first Google sign in creates a profile with only the allowed fields',
    () async {
      final (:auth, :repository) = build();

      await repository.signInWithGoogle();

      final credential = auth.credentialUsed as OAuthCredential;
      expect(credential.providerId, 'google.com');
      expect(credential.idToken, 'google-id-token');
      expect(credential.accessToken, 'google-access-token');
      final data = (await profile())!;
      expect(data.keys, unorderedEquals(['displayName', 'email', 'createdAt']));
      expect(data['displayName'], 'Aline Uwase');
      expect(data['email'], 'passenger@gmail.com');
      expect(data['createdAt'], isA<Timestamp>());
    },
  );

  test('the auth stream shows the Google passenger as verified', () async {
    final repository = build().repository;
    final users = <AuthUser?>[];
    final listener = repository.authStateChanges().listen(users.add);
    addTearDown(listener.cancel);

    await repository.signInWithGoogle();
    await Future<void>.delayed(Duration.zero);

    expect(users.last?.id, 'google-passenger-1');
    expect(users.last?.emailVerified, isTrue);
  });

  test('an existing profile is left untouched', () async {
    final saved = {
      'displayName': 'Menes',
      'email': 'passenger@gmail.com',
      'createdAt': Timestamp.fromDate(DateTime(2026, 10, 20)),
      'trustScore': 15,
    };
    await store.collection('passengers').doc('google-passenger-1').set(saved);
    final repository = build().repository;

    await repository.signInWithGoogle();

    expect(await profile(), saved);
  });

  test('a cancelled sign in fails politely and changes nothing', () async {
    google.cancel = true;
    final (:auth, :repository) = build();

    await expectLater(
      repository.signInWithGoogle(),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          'Google sign-in was cancelled',
        ),
      ),
    );
    expect(auth.credentialUsed, isNull);
    expect(await profile(), isNull);
    expect(google.signOuts, 0);
  });

  test('a Google network error becomes a NetworkFailure', () async {
    google.failure = PlatformException(code: GoogleSignIn.kNetworkError);
    final repository = build().repository;

    await expectLater(
      repository.signInWithGoogle(),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('a Firebase refusal releases the picked Google account', () async {
    final (:auth, :repository) = build();
    auth.failure = FirebaseAuthException(
      code: 'account-exists-with-different-credential',
    );

    await expectLater(
      repository.signInWithGoogle(),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('another sign-in method'),
        ),
      ),
    );
    expect(google.signOuts, 1);
    expect(await profile(), isNull);
  });

  test('a Google account without an email is signed out again', () async {
    final (:auth, :repository) = build(_User(email: null));

    await expectLater(
      repository.signInWithGoogle(),
      throwsA(isA<AuthFailure>()),
    );
    expect(auth.currentUser, isNull);
    expect(auth.signOuts, 1);
    expect(google.signOuts, 1);
    expect(await profile(), isNull);
  });

  test('signing out of a Google account also signs out of Google', () async {
    final (:auth, :repository) = build();
    await repository.signInWithGoogle();

    await repository.signOut();

    expect(auth.currentUser, isNull);
    expect(google.signOuts, 1);
  });

  test('signing out of an email account does not touch Google', () async {
    final (:auth, :repository) = build(_User(providers: const ['password']));
    auth.currentUser = auth.googleUser;

    await repository.signOut();

    expect(auth.currentUser, isNull);
    expect(google.signOuts, 0);
  });

  group('passengerNameFor', () {
    test('uses the Google name with tidy spaces', () {
      expect(
        passengerNameFor('  Aline   Uwase ', 'a@gmail.com'),
        'Aline Uwase',
      );
    });

    test('falls back to the email before the @', () {
      expect(passengerNameFor(null, 'aline.u@gmail.com'), 'aline.u');
      expect(passengerNameFor('   ', 'aline.u@gmail.com'), 'aline.u');
    });

    test('falls back to Passenger when nothing is usable', () {
      expect(passengerNameFor(null, '@gmail.com'), 'Passenger');
    });

    test('keeps at most 80 characters', () {
      final name = passengerNameFor('A' * 120, 'a@gmail.com');
      expect(name.length, 80);
    });
  });
}
