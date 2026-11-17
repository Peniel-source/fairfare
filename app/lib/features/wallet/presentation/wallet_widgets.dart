// Small stateless pieces of the Wallet screen (D4).
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../report/domain/entities/report_enums.dart';
import '../domain/entities/cash_out_request.dart';
import '../domain/entities/wallet.dart';
import '../domain/entities/wallet_entry.dart';

/// Pending and finalized balances side by side.
class WalletBalances extends StatelessWidget {
  const WalletBalances({super.key, required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _BalanceCard(
              title: 'Finalized',
              points: wallet.finalizedBalance,
              caption: 'Ready to cash out',
              icon: Icons.account_balance_wallet_outlined,
              highlighted: true,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _BalanceCard(
              title: 'Pending',
              points: wallet.pendingBalance,
              caption: 'In the review window',
              icon: Icons.hourglass_top,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.title,
    required this.points,
    required this.caption,
    required this.icon,
    this.highlighted = false,
  });

  final String title;
  final int points;
  final String caption;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$title balance, ${Formatters.points(points)}. $caption',
      excludeSemantics: true,
      child: AppCard(
        color: highlighted
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    title.toUpperCase(),
                    style: AppTypography.eyebrow(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Formatters.points(points),
                style: AppTypography.price(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(caption, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Section heading in the uppercase eyebrow style.
class WalletSectionTitle extends StatelessWidget {
  const WalletSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        top: AppSpacing.xl,
        bottom: AppSpacing.sm,
      ),
      child: Text(text.toUpperCase(), style: AppTypography.eyebrow(context)),
    );
  }
}

/// One reward in the history list.
class WalletEntryTile extends StatelessWidget {
  const WalletEntryTile({super.key, required this.entry});

  final WalletEntry entry;

  bool get _isFinalized => entry.state == 'finalized';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ListRow(
      icon: Icons.star_outline,
      title: '+${Formatters.points(entry.amount)}',
      subtitle: 'Verified report reward · ${Formatters.date(entry.createdAt)}',
      chip: StateChip(
        label: _isFinalized ? 'Finalized' : 'Pending',
        icon: _isFinalized ? Icons.check_circle_outline : Icons.hourglass_top,
        color: _isFinalized
            ? theme.colorScheme.primary
            : theme.extension<AppPalette>()?.accent ?? AppColors.orange,
      ),
    );
  }
}

/// One cash out request and where it stands.
class CashOutRequestTile extends StatelessWidget {
  const CashOutRequestTile({super.key, required this.request});

  final CashOutRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, icon, color) = switch (request.status) {
      CashOutStatus.pending => (
        'Pending',
        Icons.hourglass_top,
        theme.extension<AppPalette>()?.accent ?? AppColors.orange,
      ),
      CashOutStatus.paid => (
        'Paid',
        Icons.check_circle_outline,
        theme.colorScheme.primary,
      ),
      CashOutStatus.rejected => (
        'Rejected',
        Icons.cancel_outlined,
        theme.colorScheme.error,
      ),
    };
    return _ListRow(
      icon: Icons.payments_outlined,
      title: '−${Formatters.points(request.amount)}',
      subtitle: '${request.method} · ${Formatters.date(request.createdAt)}',
      chip: StateChip(label: label, icon: icon, color: color),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chip,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget chip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          chip,
        ],
      ),
    );
  }
}

/// Small pill that shows a state. The label stays in the main text color so
/// it keeps 4.5 to 1 contrast; the state color goes on the tint and icon.
class StateChip extends StatelessWidget {
  const StateChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
