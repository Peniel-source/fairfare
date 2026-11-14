/// Rider profile with trust score, streak, and badges.
class Rider {
  final String id;
  final String displayName;
  final String email;
  final int trustScore;
  final int streak;
  final List<String> badges;

  const Rider({
    required this.id,
    required this.displayName,
    required this.email,
    this.trustScore = 0,
    this.streak = 0,
    List<String>? badges,
  }) : badges = badges ?? const [];

  Rider copyWith({
    String? displayName,
    int? trustScore,
    int? streak,
    List<String>? badges,
  }) {
    return Rider(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      trustScore: trustScore ?? this.trustScore,
      streak: streak ?? this.streak,
      badges: badges ?? this.badges,
    );
  }
}
