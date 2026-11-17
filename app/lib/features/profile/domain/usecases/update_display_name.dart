// Update the passenger's display name.
import '../repositories/profile_repository.dart';

class UpdateDisplayName {
  final ProfileRepository repository;

  UpdateDisplayName(this.repository);

  Future<void> call(String name) {
    return repository.updateDisplayName(name);
  }
}
