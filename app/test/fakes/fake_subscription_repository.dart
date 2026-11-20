// Test-only fake of SubscriptionRepository. It lives under test/ so the app
// can never show a fake Pass; widget tests call approve()/reject() to play
// the part of the E3 backend.
import 'dart:async';

import 'package:fairfare/core/constants/app_constants.dart';
import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/features/pass/domain/entities/subscription.dart';
import 'package:fairfare/features/pass/domain/repositories/subscription_repository.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  final _controller = StreamController<Subscription?>.broadcast();
  Subscription? _subscription;

  /// References already used by anyone. In Firestore the reference is the
  /// subscription document id, so the rules refuse a second create.
  final _usedReferences = <String>{'1000000001'};

  @override
  Stream<Subscription?> watchMine() async* {
    yield _subscription;
    yield* _controller.stream;
  }

  @override
  Future<void> submitReference(String reference, int amount) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_usedReferences.add(reference)) {
      throw const DuplicateReferenceFailure();
    }
    _emit(
      Subscription(
        reference: reference,
        amount: amount,
        status: SubscriptionStatus.pending,
      ),
    );
  }

  /// Simulates E3 approving the pending subscription.
  void approve(String reference, {DateTime? now}) {
    final current = _subscription;
    if (current == null ||
        current.reference != reference ||
        current.status != SubscriptionStatus.pending) {
      return;
    }
    final startsAt = now ?? DateTime.now();
    _emit(
      Subscription(
        reference: reference,
        amount: current.amount,
        status: SubscriptionStatus.active,
        startsAt: startsAt,
        endsAt: startsAt.add(AppConstants.subscriptionDuration),
      ),
    );
  }

  /// Simulates E3 rejecting the pending subscription.
  void reject(String reference) {
    final current = _subscription;
    if (current == null || current.reference != reference) return;
    _emit(
      Subscription(
        reference: reference,
        amount: current.amount,
        status: SubscriptionStatus.rejected,
      ),
    );
  }

  void _emit(Subscription subscription) {
    _subscription = subscription;
    _controller.add(subscription);
  }

  void dispose() => _controller.close();
}
