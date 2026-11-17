// Sign in with email and password.
import '../repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository repository;

  SignInWithEmail(this.repository);

  Future<void> call(String email, String password) {
    return repository.signInWithEmail(email, password);
  }
}
