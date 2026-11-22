// Test-only fake of ProfileRepository. It lives under test/ so the app can
// never show a made-up profile or leaderboard.
import 'dart:async';

import 'package:fairfare/features/profile/domain/badges.dart';
import 'package:fairfare/features/profile/domain/entities/leaderboard_entry.dart';
import 'package:fairfare/features/profile/domain/entities/passenger.dart';
import 'package:fairfare/features/profile/domain/repositories/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  /// Pass [me] or [leaderboard] to try other states (for example a brand new
  /// passenger with a score of 0 and no badges).
  FakeProfileRepository({Passenger? me, List<LeaderboardEntry>? leaderboard})
    : _passenger = me ?? sampleMe,
      _leaderboard = leaderboard ?? sampleLeaderboard;

  static final sampleMe = Passenger(
    id: 'fake_user_1',
    displayName: 'Test Passenger',
    email: 'test@example.com',
    trustScore: 15,
    streak: 3,
    badges: [Badges.corridorPioneer.id],
    verifiedCount: 4,
    lastReportDate: DateTime(2026, 11, 13),
  );

  static const sampleLeaderboard = <LeaderboardEntry>[
    LeaderboardEntry(id: 'u1', displayName: 'Alice', trustScore: 85),
    LeaderboardEntry(id: 'u2', displayName: 'Bob', trustScore: 72),
    LeaderboardEntry(id: 'u3', displayName: 'Charlie', trustScore: 60),
    LeaderboardEntry(id: 'u4', displayName: 'Diana', trustScore: 50),
    LeaderboardEntry(id: 'u5', displayName: 'Eve', trustScore: 40),
    LeaderboardEntry(id: 'u6', displayName: 'Frank', trustScore: 35),
    LeaderboardEntry(id: 'u7', displayName: 'Grace', trustScore: 30),
    LeaderboardEntry(id: 'u8', displayName: 'Henry', trustScore: 25),
    LeaderboardEntry(id: 'u9', displayName: 'Ines', trustScore: 20),
    LeaderboardEntry(
      id: 'fake_user_1',
      displayName: 'Test Passenger',
      trustScore: 15,
    ),
    LeaderboardEntry(id: 'u11', displayName: 'Jean', trustScore: 10),
  ];

  final _meController = StreamController<Passenger>.broadcast();
  final _leaderboardController =
      StreamController<List<LeaderboardEntry>>.broadcast();
  Passenger _passenger;
  List<LeaderboardEntry> _leaderboard;

  /// Emits the current passenger first, then every change.
  @override
  Stream<Passenger> watchMe() async* {
    yield _passenger;
    yield* _meController.stream;
  }

  /// Highest score first, like the Firestore query (trustScore descending).
  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() async* {
    yield _sorted();
    yield* _leaderboardController.stream;
  }

  @override
  Future<void> updateDisplayName(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _passenger = _passenger.copyWith(displayName: name);
    _meController.add(_passenger);
    // The server copies the new name onto the public leaderboard row.
    _leaderboard = [
      for (final e in _leaderboard)
        e.id == _passenger.id
            ? LeaderboardEntry(
                id: e.id,
                displayName: name,
                trustScore: e.trustScore,
              )
            : e,
    ];
    _leaderboardController.add(_sorted());
  }

  List<LeaderboardEntry> _sorted() => List.unmodifiable(
    [..._leaderboard]..sort((a, b) => b.trustScore.compareTo(a.trustScore)),
  );

  void dispose() {
    _meController.close();
    _leaderboardController.close();
  }
}
