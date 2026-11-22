// Riverpod providers for the profile feature.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/profile_repository_impl.dart';
import '../domain/entities/leaderboard_entry.dart';
import '../domain/entities/passenger.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/usecases/update_display_name.dart';

/// How many rows the leaderboard shows.
const kLeaderboardSize = 10;

/// Provider for the ProfileRepository implementation.
///
/// Always the real Firestore repository: each signed-in passenger sees only
/// their own profile (passengers/{uid}). Rebuilt on sign in and sign out, so
/// one account never sees another's data.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final uid = ref.watch(
    authStateProvider.select((auth) => auth.valueOrNull?.id),
  );
  return ProfileRepositoryImpl(FirebaseFirestore.instance, uid: uid);
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

/// State of the "save avatar" action in the avatar picker.
class ChooseAvatarController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns true when the avatar was saved.
  Future<bool> save(String avatarId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).updateAvatar(avatarId),
    );
    return !state.hasError;
  }
}

final chooseAvatarControllerProvider =
    AsyncNotifierProvider.autoDispose<ChooseAvatarController, void>(
      ChooseAvatarController.new,
    );

final editDisplayNameControllerProvider =
    AsyncNotifierProvider.autoDispose<EditDisplayNameController, void>(
      EditDisplayNameController.new,
    );

/// Friendly text for an error coming out of the Profile feature.
String profileErrorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'Something went wrong. Check your connection and try again';
}
