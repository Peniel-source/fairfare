// Riverpod providers for the profile feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../data/fake_profile_repository.dart';
import '../domain/entities/leaderboard_entry.dart';
import '../domain/entities/passenger.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/usecases/update_display_name.dart';

/// How many rows the leaderboard shows.
const kLeaderboardSize = 10;

/// Provider for the ProfileRepository implementation.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (AppConstants.useFakeData) {
    final fake = FakeProfileRepository();
    ref.onDispose(fake.dispose);
    return fake;
  }
  // TODO(E4): return ProfileRepositoryImpl() when real Firestore wiring is ready.
  throw UnimplementedError('ProfileRepositoryImpl not yet implemented');
});

/// Stream of the current passenger's profile.
final meProvider = StreamProvider<Passenger>((ref) {
  return ref.watch(profileRepositoryProvider).watchMe();
});

/// Top [kLeaderboardSize] passengers by trust score, highest first.
final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref
      .watch(profileRepositoryProvider)
      .watchLeaderboard()
      .map((rows) => rows.take(kLeaderboardSize).toList());
});

/// Use case provider.
final updateDisplayNameProvider = Provider<UpdateDisplayName>((ref) {
  return UpdateDisplayName(ref.watch(profileRepositoryProvider));
});

/// State of the "save display name" action, so the edit dialog keeps no app
/// state of its own.
class EditDisplayNameController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns true when the name was saved.
  Future<bool> save(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(updateDisplayNameProvider).call(name),
    );
    return !state.hasError;
  }
}

final editDisplayNameControllerProvider =
    AsyncNotifierProvider.autoDispose<EditDisplayNameController, void>(
      EditDisplayNameController.new,
    );

/// Friendly text for an error coming out of the Profile feature.
String profileErrorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'Something went wrong. Check your connection and try again';
}
