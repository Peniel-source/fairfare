// Repository for passenger profile and leaderboard.
import '../entities/leaderboard_entry.dart';
import '../entities/passenger.dart';

abstract class ProfileRepository {
  Stream<Passenger> watchMe();
  Future<void> updateDisplayName(String name);

  /// Top passengers by trust score, highest first.
  Stream<List<LeaderboardEntry>> watchLeaderboard();
}
