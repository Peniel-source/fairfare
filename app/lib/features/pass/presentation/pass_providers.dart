// Riverpod providers for the pass (subscription) feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/fake_subscription_repository.dart';
import '../domain/entities/subscription.dart';
import '../domain/repositories/subscription_repository.dart';
import '../domain/usecases/submit_payment_reference.dart';

/// Provider for the SubscriptionRepository implementation.
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  if (AppConstants.useFakeData) {
    return FakeSubscriptionRepository();
  }
  // TODO(E2): return SubscriptionRepositoryImpl() when real Firestore wiring is ready.
  throw UnimplementedError('SubscriptionRepositoryImpl not yet implemented');
});

/// Stream of the current rider's subscription.
final subscriptionProvider = StreamProvider<Subscription?>((ref) {
  return ref.watch(subscriptionRepositoryProvider).watchMine();
});

/// Use case provider.
final submitPaymentReferenceProvider = Provider<SubmitPaymentReference>((ref) {
  return SubmitPaymentReference(ref.watch(subscriptionRepositoryProvider));
});
