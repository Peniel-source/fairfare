// Wallet tab (D4): pending and finalized points, reward history, cash out.
//
// Everything is a live stream from WalletRepository (Firestore), so balances
// change on screen as soon as the server moves a reward from pending to
// finalized.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/home_app_bar.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/entities/wallet.dart';
import 'cash_out_sheet.dart';
import 'wallet_providers.dart';
import 'wallet_widgets.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      appBar: const HomeAppBar(),
      body: wallet.when(
        loading: () => const LoadingView(message: 'Loading your wallet'),
        error: (_, _) => ErrorView(
          message:
              'We could not load your wallet. Check your connection '
              'and try again.',
          onRetry: () => ref.invalidate(walletProvider),
        ),
        data: (wallet) => _WalletContent(wallet: wallet),
      ),
    );
  }
}

class _WalletContent extends ConsumerWidget {
  const _WalletContent({required this.wallet});

  final Wallet wallet;

  Future<void> _openCashOut(BuildContext context) async {
    final sent = await showCashOutSheet(
      context,
      finalizedBalance: wallet.finalizedBalance,
    );
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cash out requested. We will update its status here.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCashOut = wallet.finalizedBalance > 0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(walletProvider);
        ref.invalidate(walletEntriesProvider);
        ref.invalidate(cashOutRequestsProvider);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              Text('Wallet', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              WalletBalances(wallet: wallet),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Cash out',
                icon: Icons.payments_outlined,
                expand: true,
                onPressed: canCashOut ? () => _openCashOut(context) : null,
              ),
              if (!canCashOut) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Rewards become finalized after their review window. '
                  'You can cash out once you have finalized points.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const WalletSectionTitle('Reward history'),
              const _EntriesSection(),
              const WalletSectionTitle('Cash out requests'),
              const _CashOutRequestsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntriesSection extends ConsumerWidget {
  const _EntriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(walletEntriesProvider);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: entries.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => ErrorView(
          compact: true,
          message: 'Could not load your reward history.',
          onRetry: () => ref.invalidate(walletEntriesProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyView(
                compact: true,
                icon: Icons.star_outline,
                title: 'No rewards yet',
                message:
                    'Report the fare you paid. When another passenger confirms '
                    'it, you earn points.',
              )
            : Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    WalletEntryTile(entry: list[i]),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CashOutRequestsSection extends ConsumerWidget {
  const _CashOutRequestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(cashOutRequestsProvider);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: requests.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => ErrorView(
          compact: true,
          message: 'Could not load your cash out requests.',
          onRetry: () => ref.invalidate(cashOutRequestsProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyView(
                compact: true,
                icon: Icons.payments_outlined,
                title: 'No cash out requests',
                message: 'Requests you make show here with their status.',
              )
            : Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    CashOutRequestTile(request: list[i]),
                  ],
                ],
              ),
      ),
    );
  }
}
