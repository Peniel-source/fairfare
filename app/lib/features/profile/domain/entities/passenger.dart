/// Passenger profile with trust score, streak, and badges.
///
/// trustScore, streak, badges, verifiedCount and lastReportDate are written
/// only by the server (E5). The app may change displayName only.
class Passenger {
  final String id;
  final String displayName;
  final String email;
  final int trustScore;
  final int streak;
  final List<String> badges;

  /// Number of verified reports; drives the Ten Verified badge.
  final int verifiedCount;

  /// Day of the last report that was not rejected; drives the streak.
  /// Null for a passenger who has never reported.
  final DateTime? lastReportDate;

  const Passenger({
    required this.id,
    required this.displayName,
    required this.email,
    this.trustScore = 0,
    this.streak = 0,
    List<String>? badges,
    this.verifiedCount = 0,
    this.lastReportDate,
  }) : badges = badges ?? const [];

  Passenger copyWith({
    String? displayName,
    int? trustScore,
    int? streak,
    List<String>? badges,
    int? verifiedCount,
    DateTime? lastReportDate,
  }) {
    return Passenger(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      trustScore: trustScore ?? this.trustScore,
      streak: streak ?? this.streak,
      badges: badges ?? this.badges,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      lastReportDate: lastReportDate ?? this.lastReportDate,
    );
  }
}
