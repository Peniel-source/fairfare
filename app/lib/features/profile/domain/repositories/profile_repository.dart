// Repository for rider profile and leaderboard.
import '../entities/rider.dart';

abstract class ProfileRepository {
  Stream<Rider> watchMe();
  Future<void> updateDisplayName(String name);
  Stream<List<Rider>> watchLeaderboard();
}
