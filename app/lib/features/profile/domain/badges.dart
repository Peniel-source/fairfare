// The badges a passenger can earn (task guide section 4).
//
// passengers/{uid}.badges stores the ids below. The server (E5) writes them;
// the app only reads them. Keep these ids identical in backend/src/engagement.

class BadgeInfo {
  final String id;
  final String title;

  /// How to earn it, shown on locked badges.
  final String howToEarn;

  const BadgeInfo({
    required this.id,
    required this.title,
    required this.howToEarn,
  });
}

abstract final class Badges {
  static const corridorPioneer = BadgeInfo(
    id: 'corridor_pioneer',
    title: 'Corridor Pioneer',
    howToEarn: 'Make the first verified report on a corridor',
  );
  static const weekStreak = BadgeInfo(
    id: 'week_streak',
    title: 'Week Streak',
    howToEarn: 'Report 7 days in a row',
  );
  static const tenVerified = BadgeInfo(
    id: 'ten_verified',
    title: 'Ten Verified',
    howToEarn: 'Get 10 reports verified',
  );

  /// Display order on the profile.
  static const all = [corridorPioneer, weekStreak, tenVerified];
}
