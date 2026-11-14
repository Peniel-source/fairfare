// Fake subscription repository with sample data.
import 'dart:async';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/subscription.dart';
import '../domain/repositories/subscription_repository.dart';
import '../../report/domain/entities/report_enums.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({this.autoApproveAfter});

  /// When set, a submitted reference is approved by itself after this delay,
  /// standing in for E3's approval endpoint during screen work.
  final Duration? autoApproveAfter;

  final _controller = StreamController<Subscription?>.broadcast();
  Subscription? _subscription;

  /// References already used by anyone. In Firestore the reference is the
  /// subscription document id, so the rules refuse a second create.
  final _usedReferences = <String>{'USED123456'};

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
    final delay = autoApproveAfter;
    if (delay != null) {
      Future.delayed(delay, () => approve(reference));
    }
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
