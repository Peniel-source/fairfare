// Register a new user with email and password.
import '../repositories/auth_repository.dart';

class RegisterWithEmail {
  final AuthRepository repository;

  RegisterWithEmail(this.repository);

  Future<void> call(String email, String password, String displayName) {
    return repository.registerWithEmail(email, password, displayName);
  }
}
