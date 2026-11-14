// Fake profile repository with sample data.
import 'dart:async';

import '../domain/entities/rider.dart';
import '../domain/repositories/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  final _meController = StreamController<Rider>.broadcast();
  final _leaderboardController = StreamController<List<Rider>>.broadcast();

  Rider _rider = const Rider(
    id: 'fake_user_1',
    displayName: 'Test Rider',
    email: 'test@example.com',
    trustScore: 15,
    streak: 3,
    badges: ['Corridor Pioneer'],
  );

  final _leaderboard = const <Rider>[
    Rider(
      id: 'u1',
      displayName: 'Alice',
      email: 'a@e.com',
      trustScore: 85,
      streak: 10,
      badges: ['Ten Verified', 'Week Streak'],
    ),
    Rider(
      id: 'u2',
      displayName: 'Bob',
      email: 'b@e.com',
      trustScore: 72,
      streak: 7,
      badges: ['Week Streak'],
    ),
    Rider(
      id: 'u3',
      displayName: 'Charlie',
      email: 'c@e.com',
      trustScore: 60,
      streak: 5,
      badges: ['Corridor Pioneer'],
    ),
    Rider(
      id: 'u4',
      displayName: 'Diana',
      email: 'd@e.com',
      trustScore: 50,
      streak: 4,
      badges: ['Corridor Pioneer'],
    ),
    Rider(
      id: 'u5',
      displayName: 'Eve',
      email: 'e@e.com',
      trustScore: 40,
      streak: 3,
      badges: [],
    ),
  ];

  FakeProfileRepository() {
    _meController.add(_rider);
    _leaderboardController.add(_leaderboard);
  }

  @override
  Stream<Rider> watchMe() => _meController.stream;

  @override
  Stream<List<Rider>> watchLeaderboard() => _leaderboardController.stream;

  @override
  Future<void> updateDisplayName(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _rider = _rider.copyWith(displayName: name);
    _meController.add(_rider);
  }

  void dispose() {
    _meController.close();
    _leaderboardController.close();
  }
}
