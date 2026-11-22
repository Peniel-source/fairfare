import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  /// [googleSignIn] is only passed by tests. The app creates the Google client
  /// the first time it is needed.
  FirebaseAuthRepository(
    this._auth,
    this._firestore, {
    GoogleSignIn? googleSignIn,
  }) : _googleClient = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  GoogleSignIn? _googleClient;
  Completer<void>? _registration;

  GoogleSignIn get _google => _googleClient ??= GoogleSignIn();

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.userChanges().asyncMap((user) async {
        final registration = _registration;
        if (registration != null) {
          await registration.future;
          user = _auth.currentUser;
        }
        return user == null
            ? null
            : AuthUser(
                id: user.uid,
                email: user.email ?? '',
                displayName: user.displayName,
                emailVerified: user.emailVerified,
              );
      });

  @override
  Future<void> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    if (_registration != null) {
      throw const AuthFailure('Account creation is already in progress');
    }
    final registration = Completer<void>();
    _registration = registration;
    User? user;
    var profileCreated = false;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user;
      if (user == null) {
        throw const AuthFailure('Could not create your account');
      }
      await user.updateDisplayName(displayName.trim());
      await _firestore.collection(FirestorePaths.passengers).doc(user.uid).set({
        'displayName': displayName.trim(),
        'email': user.email!,
        'createdAt': FieldValue.serverTimestamp(),
      });
      profileCreated = true;
      try {
        await user.sendEmailVerification();
      } on FirebaseAuthException {
        throw const AuthFailure(
          'Your account was created, but the verification email could not be sent. Tap Resend email to try again.',
        );
      }
    } catch (error, stack) {
      if (user != null && !profileCreated) {
        try {
          await user.delete();
        } on FirebaseException {
          await _auth.signOut();
        }
      }
      Error.throwWithStackTrace(_failure(error), stack);
    } finally {
      registration.complete();
      _registration = null;
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) => _run(() async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  });

  @override
  Future<void> sendPasswordReset(String email) => _run(() async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found') rethrow;
    }
  });

  @override
  Future<void> sendEmailVerification() => _run(() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('Sign in again to verify your email');
    }
    await user.sendEmailVerification();
  });

  @override
  Future<void> reloadUser() => _run(() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('Sign in again to verify your email');
    }
    try {
      await user.reload();
      await _auth.currentUser?.getIdToken(true);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-disabled' || error.code == 'user-not-found') {
        await _auth.signOut();
      }
      rethrow;
    }
  });

  /// Signs out of Firebase, and of Google too when the passenger used it, so
  /// the next Google sign in shows the account picker again (D2).
  @override
  Future<void> signOut() => _run(() async {
    await _signOutOfGoogleIfUsed();
    await _auth.signOut();
  });

  /// Google sign in (D2).
  ///
  /// The first Google sign in creates passengers/{uid} with only the fields
  /// the rules allow. Like email registration, it holds [authStateChanges]
  /// until that profile exists, so the router never opens a screen that reads
  /// a profile which is not there yet.
  @override
  Future<void> signInWithGoogle() async {
    if (_registration != null) {
      throw const AuthFailure('Sign in is already in progress');
    }
    final registration = Completer<void>();
    _registration = registration;
    GoogleSignInAccount? account;
    User? user;
    try {
      // signIn() returns null when the passenger closes the account picker.
      account = await _google.signIn();
      if (account == null) {
        throw const AuthFailure('Google sign-in was cancelled');
      }
      final tokens = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
      user = (await _auth.signInWithCredential(credential)).user;
      if (user == null) {
        throw const AuthFailure('Could not sign in with Google');
      }
      await _ensurePassengerProfile(user);
    } catch (error, stack) {
      // Leave nothing half signed in: a picked Google account would otherwise
      // be reused silently on the next try.
      if (account != null) await _signOutOfGoogleQuietly();
      if (user != null) await _signOutOfFirebaseQuietly();
      Error.throwWithStackTrace(_googleFailure(error), stack);
    } finally {
      registration.complete();
      _registration = null;
    }
  }

  /// Creates passengers/{uid} on the first Google sign in. An existing
  /// profile (an earlier Google sign in, or an email account with the same
  /// address) is left untouched.
  Future<void> _ensurePassengerProfile(User user) async {
    final profile = _firestore
        .collection(FirestorePaths.passengers)
        .doc(user.uid);
    if ((await profile.get()).exists) return;
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const AuthFailure(
        'Your Google account has no email address. Use email sign-in instead',
      );
    }
    await profile.set({
      'displayName': passengerNameFor(user.displayName, email),
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _signOutOfGoogleIfUsed() async {
    try {
      final providers = _auth.currentUser?.providerData ?? const [];
      if (providers.any(
        (info) => info.providerId == GoogleAuthProvider.PROVIDER_ID,
      )) {
        await _google.signOut();
      }
    } catch (_) {
      // Signing out of Google only resets the account picker. It must never
      // stop the Firebase sign out.
    }
  }

  Future<void> _signOutOfGoogleQuietly() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Best effort: the original error is the one the passenger needs.
    }
  }

  Future<void> _signOutOfFirebaseQuietly() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Best effort: the original error is the one the passenger needs.
    }
  }

  Object _googleFailure(Object error) {
    if (error is PlatformException) {
      return switch (error.code) {
        GoogleSignIn.kNetworkError => const NetworkFailure(),
        GoogleSignIn.kSignInCanceledError => const AuthFailure(
          'Google sign-in was cancelled',
        ),
        _ => const AuthFailure('Google sign-in failed. Please try again'),
      };
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return const AuthFailure(
            'This email already uses another sign-in method. Sign in with '
            'your email and password',
          );
        case 'operation-not-allowed':
          return const AuthFailure('Google sign-in is currently unavailable');
        case 'invalid-credential':
          return const AuthFailure('Google sign-in failed. Please try again');
      }
    }
    return _failure(error);
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      Error.throwWithStackTrace(_failure(error), stack);
    }
  }

  Object _failure(Object error) {
    if (error is! FirebaseException) return error;
    return switch (error.code) {
      'email-already-in-use' => const EmailInUseFailure(),
      'weak-password' => const WeakPasswordFailure(),
      'invalid-email' => const InvalidEmailFailure(),
      'wrong-password' => const WrongPasswordFailure(),
      'user-not-found' => const UserNotFoundFailure(),
      'invalid-credential' || 'invalid-login-credentials' => const AuthFailure(
        'Email or password is incorrect',
      ),
      'too-many-requests' => const TooManyAttemptsFailure(),
      'network-request-failed' || 'unavailable' => const NetworkFailure(),
      'user-disabled' => const AuthFailure('This account has been disabled'),
      'operation-not-allowed' => const AuthFailure(
        'Email sign-in is currently unavailable',
      ),
      'permission-denied' => const FirestoreFailure(
        'Could not save your account. Please try again',
      ),
      _ => const AuthFailure(
        'Could not complete the request. Please try again',
      ),
    };
  }
}

/// The display name saved on a passenger's first Google sign in.
///
/// Uses the Google name, else the part of the email before the @, else
/// "Passenger". Spaces are tidied and the result is at most 80 characters,
/// so it always passes the rules' displayName check.
String passengerNameFor(String? googleName, String email) {
  final name = _tidyName(googleName ?? '');
  if (name.isNotEmpty) return name;
  final local = _tidyName(email.split('@').first);
  return local.isEmpty ? 'Passenger' : local;
}

String _tidyName(String value) {
  final tidy = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  final runes = tidy.runes;
  if (runes.length <= 80) return tidy;
  return String.fromCharCodes(runes.take(80)).trimRight();
}
