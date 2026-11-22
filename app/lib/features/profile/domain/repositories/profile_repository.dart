// Repository for passenger profile and leaderboard.
import '../entities/leaderboard_entry.dart';
import '../entities/passenger.dart';

abstract class ProfileRepository {
  Stream<Passenger> watchMe();
  Future<void> updateDisplayName(String name);

  /// Saves the avatar the passenger picked ([avatarId] from avatarPresets).
  Future<void> updateAvatar(String avatarId);

  /// Top passengers by trust score, highest first.
  Stream<List<LeaderboardEntry>> watchLeaderboard();
}
