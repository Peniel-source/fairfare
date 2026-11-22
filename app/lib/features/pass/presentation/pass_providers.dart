// Riverpod providers for the pass (subscription) feature.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/subscription_repository_impl.dart';
import '../domain/entities/subscription.dart';
import '../domain/repositories/subscription_repository.dart';
import '../domain/usecases/submit_payment_reference.dart';

/// Provider for the SubscriptionRepository implementation.
///
/// Always the real Firestore repository, even while other features run on
/// fake data: a Pass is real money, so the app never shows a made-up one.
/// Rebuilt on sign in and sign out, so it always reads the current passenger.
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final uid = ref.watch(
    authStateProvider.select((auth) => auth.valueOrNull?.id),
  );
  return SubscriptionRepositoryImpl(FirebaseFirestore.instance, uid: uid);
});

/// Stream of the current passenger's subscription.
final subscriptionProvider = StreamProvider<Subscription?>((ref) {
  return ref.watch(subscriptionRepositoryProvider).watchMine();
});

/// Use case provider.
final submitPaymentReferenceProvider = Provider<SubmitPaymentReference>((ref) {
  return SubmitPaymentReference(ref.watch(subscriptionRepositoryProvider));
});

/// Holds the state of the "submit reference" action (idle, sending, error),
/// so the form widget keeps no app state of its own.
class SubmitReferenceController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns true when the reference was accepted.
  Future<bool> submit(String reference) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(submitPaymentReferenceProvider)
          .call(reference, AppConstants.passPriceRwf),
    );
    return !state.hasError;
  }
}

final submitReferenceControllerProvider =
    AsyncNotifierProvider.autoDispose<SubmitReferenceController, void>(
      SubmitReferenceController.new,
    );

/// Friendly text for an error coming out of the Pass feature.
String passErrorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'Something went wrong. Check your connection and try again';
}
