// Repository for Pass subscription.
import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Stream<Subscription?> watchMine();
  Future<void> submitReference(String reference, int amount);
}
