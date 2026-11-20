import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  Completer<void>? _registration;

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

  @override
  Future<void> signOut() => _run(_auth.signOut);

  @override
  Future<void> signInWithGoogle() async {
    throw const AuthFailure('Google sign-in is not available yet');
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
