// Riverpod providers for the profile feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/fake_profile_repository.dart';
import '../domain/entities/leaderboard_entry.dart';
import '../domain/entities/passenger.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/usecases/update_display_name.dart';

/// Provider for the ProfileRepository implementation.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (AppConstants.useFakeData) {
    return FakeProfileRepository();
  }
  // TODO(E4): return ProfileRepositoryImpl() when real Firestore wiring is ready.
  throw UnimplementedError('ProfileRepositoryImpl not yet implemented');
});

/// Stream of the current passenger's profile.
final meProvider = StreamProvider<Passenger>((ref) {
  return ref.watch(profileRepositoryProvider).watchMe();
});

/// Stream of the leaderboard (top passengers).
final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(profileRepositoryProvider).watchLeaderboard();
});

/// Use case provider.
final updateDisplayNameProvider = Provider<UpdateDisplayName>((ref) {
  return UpdateDisplayName(ref.watch(profileRepositoryProvider));
});
