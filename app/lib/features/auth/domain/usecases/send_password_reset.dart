// Send a password reset email.
import '../repositories/auth_repository.dart';

class SendPasswordReset {
  final AuthRepository repository;

  SendPasswordReset(this.repository);

  Future<void> call(String email) {
    return repository.sendPasswordReset(email);
  }
}
