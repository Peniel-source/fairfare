// Riverpod providers for the auth feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/fake_auth_repository.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/register_with_email.dart';
import '../domain/usecases/sign_in_with_email.dart';
import '../domain/usecases/sign_in_with_google.dart';
import '../domain/usecases/send_password_reset.dart';
import '../domain/usecases/sign_out.dart';

/// Provider for the AuthRepository implementation.
/// Switches between fake and real based on [AppConstants.useFakeData].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConstants.useFakeData) {
    return FakeAuthRepository();
  }
  // TODO(B4): return AuthRepositoryImpl() when real Firestore wiring is ready.
  throw UnimplementedError('AuthRepositoryImpl not yet implemented');
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
