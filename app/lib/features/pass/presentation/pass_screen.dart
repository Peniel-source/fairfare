// Pass tab (E2): pay with mobile money, enter the reference, watch the status
// flip from pending to active live.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
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
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PassStatusCard(subscription: subscription),
            if (_canSubmit) ...[
              const SizedBox(height: 12),
              const DialPromptCard(
                dialCode: AppConstants.passDialCode,
                merchantCode: AppConstants.passMerchantCode,
                priceRwf: AppConstants.passPriceRwf,
              ),
              const SizedBox(height: 12),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
