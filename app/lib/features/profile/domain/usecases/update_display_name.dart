// Update the passenger's display name.
import '../../../../core/errors/failures.dart';
import '../display_name.dart';
import '../repositories/profile_repository.dart';

class UpdateDisplayName {
  final ProfileRepository repository;

  UpdateDisplayName(this.repository);

  /// Validates and normalizes the name, then saves it.
  /// Throws [ValidationFailure] for an invalid name.
  Future<void> call(String name) async {
    final error = validateDisplayName(name);
    if (error != null) throw ValidationFailure(error);
    return repository.updateDisplayName(normalizeDisplayName(name));
  }
}
