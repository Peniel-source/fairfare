// Pass tab (E2): pay with mobile money, enter the reference, watch the status
// flip from pending to active live.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/home_app_bar.dart';
import '../../report/domain/entities/report_enums.dart';
import '../domain/entities/subscription.dart';
import 'dial_prompt_card.dart';
import 'pass_providers.dart';
import 'pass_status_card.dart';
import 'reference_form.dart';

class PassScreen extends ConsumerWidget {
  const PassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    // Celebrate the moment the server verifies the payment, live.
    ref.listen(subscriptionProvider, (previous, next) {
      if (justApproved(previous?.valueOrNull, next.valueOrNull)) {
        // Replace "Reference sent" if it is still up, so the success shows
        // the moment it happens instead of waiting in the queue.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Payment successful. Your Pass is now active'),
            ),
          );
      }
    });

    return Scaffold(
      appBar: const HomeAppBar(),
      body: subscription.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PassError(
          message: passErrorMessage(error),
          onRetry: () => ref.invalidate(subscriptionProvider),
        ),
        data: (sub) => _PassContent(subscription: sub),
      ),
    );
  }
}

/// True when the same payment just went from pending to active.
bool justApproved(Subscription? previous, Subscription? next) =>
    previous != null &&
    next != null &&
    previous.reference == next.reference &&
    previous.status == SubscriptionStatus.pending &&
    next.status == SubscriptionStatus.active;

class _PassContent extends StatelessWidget {
  const _PassContent({required this.subscription});

  final Subscription? subscription;

  /// The form shows when there is nothing pending or active to wait on.
  bool get _canSubmit =>
      subscription == null ||
      subscription!.status == SubscriptionStatus.rejected;

  @override
  Widget build(BuildContext context) {
    return Center(
      // Keeps cards readable on tablets and in landscape.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            PassStatusCard(subscription: subscription),
            if (_canSubmit) ...[
              const SizedBox(height: AppSpacing.md),
              const DialPromptCard(
                dialCode: AppConstants.passDialCode,
                merchantCode: AppConstants.passMerchantCode,
                priceRwf: AppConstants.passPriceRwf,
              ),
              const SizedBox(height: AppSpacing.md),
              const ReferenceForm(),
            ],
          ],
        ),
      ),
    );
  }
}

class _PassError extends StatelessWidget {
  const _PassError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
