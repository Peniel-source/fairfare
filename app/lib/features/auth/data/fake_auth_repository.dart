// Fake auth repository that returns sample data for UI development.
import 'dart:async';

import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  AuthUser? _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;
  final _controller = StreamController<AuthUser?>.broadcast();

  @override
  Future<void> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = AuthUser(
      id: 'fake_user_1',
      email: email,
      displayName: displayName,
      emailVerified: false,
    );
    _controller.add(_currentUser);
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = AuthUser(
      id: 'fake_user_1',
      email: email,
      displayName: 'Test Rider',
      emailVerified: true,
    );
    _controller.add(_currentUser);
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = AuthUser(
      id: 'fake_google_1',
      email: 'rider@gmail.com',
      displayName: 'Google Rider',
      emailVerified: true,
    );
    _controller.add(_currentUser);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> sendEmailVerification() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> reloadUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_currentUser != null) {
      _currentUser = AuthUser(
        id: _currentUser!.id,
        email: _currentUser!.email,
        displayName: _currentUser!.displayName,
        emailVerified: true,
      );
      _controller.add(_currentUser);
    }
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
