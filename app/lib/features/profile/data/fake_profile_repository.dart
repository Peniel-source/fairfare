// Fake profile repository with sample data.
import 'dart:async';

import '../domain/entities/leaderboard_entry.dart';
import '../domain/entities/passenger.dart';
import '../domain/repositories/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  final _meController = StreamController<Passenger>.broadcast();

  Passenger _passenger = Passenger(
    id: 'fake_user_1',
    displayName: 'Test Passenger',
    email: 'test@example.com',
    trustScore: 15,
    streak: 3,
    badges: const ['Corridor Pioneer'],
    verifiedCount: 4,
    lastReportDate: DateTime(2026, 11, 13),
  );

  static const _leaderboard = <LeaderboardEntry>[
    LeaderboardEntry(id: 'u1', displayName: 'Alice', trustScore: 85),
    LeaderboardEntry(id: 'u2', displayName: 'Bob', trustScore: 72),
    LeaderboardEntry(id: 'u3', displayName: 'Charlie', trustScore: 60),
    LeaderboardEntry(id: 'u4', displayName: 'Diana', trustScore: 50),
    LeaderboardEntry(id: 'u5', displayName: 'Eve', trustScore: 40),
    LeaderboardEntry(
      id: 'fake_user_1',
      displayName: 'Test Passenger',
      trustScore: 15,
    ),
  ];

  /// Emits the current passenger first, then every change.
  @override
  Stream<Passenger> watchMe() async* {
    yield _passenger;
    yield* _meController.stream;
  }

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() async* {
    yield _leaderboard;
  }

  @override
  Future<void> updateDisplayName(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _passenger = _passenger.copyWith(displayName: name);
    _meController.add(_passenger);
  }

  void dispose() => _meController.close();
}
