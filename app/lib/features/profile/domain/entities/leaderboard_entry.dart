// One row of the public leaderboard (B1: leaderboard/{uid}).
//
// The leaderboard is a separate, publicly readable projection of a passenger,
// so it carries only the public fields. Private fields such as email stay in
// passengers/{uid}, which only its owner can read. Only the server writes it.
class LeaderboardEntry {
  /// The passenger's uid (the leaderboard document id).
  final String id;
  final String displayName;
  final int trustScore;

  /// Avatar id the passenger picked, or null.
  final String? avatar;

  const LeaderboardEntry({
    required this.id,
    required this.displayName,
    required this.trustScore,
    this.avatar,
  });
}
