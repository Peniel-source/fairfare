// Fake subscription repository with sample data.
import 'dart:async';

import '../domain/entities/subscription.dart';
import '../domain/repositories/subscription_repository.dart';
import '../../report/domain/entities/report_enums.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  final _controller = StreamController<Subscription?>.broadcast();
  Subscription? _subscription;

  FakeSubscriptionRepository() {
    _controller.add(null);
  }

  @override
  Stream<Subscription?> watchMine() => _controller.stream;

  @override
  Future<void> submitReference(String reference, int amount) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _subscription = Subscription(
      reference: reference,
      amount: amount,
      status: SubscriptionStatus.pending,
    );
    _controller.add(_subscription);
  }

  void dispose() => _controller.close();
}
