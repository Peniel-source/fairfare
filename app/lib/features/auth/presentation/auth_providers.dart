// Riverpod providers for the auth feature.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/register_with_email.dart';
import '../domain/usecases/sign_in_with_email.dart';
import '../domain/usecases/sign_in_with_google.dart';
import '../domain/usecases/send_password_reset.dart';
import '../domain/usecases/sign_out.dart';

/// Provider for the AuthRepository implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

/// Stream of the current authenticated user.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Use case providers.
final registerWithEmailProvider = Provider<RegisterWithEmail>((ref) {
  return RegisterWithEmail(ref.watch(authRepositoryProvider));
});

final signInWithEmailProvider = Provider<SignInWithEmail>((ref) {
  return SignInWithEmail(ref.watch(authRepositoryProvider));
});

final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(ref.watch(authRepositoryProvider));
});

final sendPasswordResetProvider = Provider<SendPasswordReset>((ref) {
  return SendPasswordReset(ref.watch(authRepositoryProvider));
});

final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});

class AuthController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> signIn(String email, String password) => _run(
    () => ref.read(signInWithEmailProvider).call(email.trim(), password),
  );

  Future<bool> register(String email, String password, String displayName) =>
      _run(
        () => ref
            .read(registerWithEmailProvider)
            .call(email.trim(), password, displayName.trim()),
      );

  Future<bool> resetPassword(String email) =>
      _run(() => ref.read(sendPasswordResetProvider).call(email.trim()));

  Future<bool> resendVerification() =>
      _run(() => ref.read(authRepositoryProvider).sendEmailVerification());

  Future<bool> checkVerification() =>
      _run(() => ref.read(authRepositoryProvider).reloadUser());

  Future<bool> signOut() => _run(() => ref.read(signOutProvider).call());

  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

String authErrorMessage(Object error) => error is Failure
    ? error.message
    : 'Could not complete the request. Please try again';
