// Cash out bottom sheet (D4): amount + payout method, validated, then a
// pending cashOutRequest is created through the RequestCashOut use case.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../domain/cash_out_rules.dart';
import 'wallet_providers.dart';

/// Opens the sheet. Resolves to true when a request was sent.
Future<bool?> showCashOutSheet(
  BuildContext context, {
  required int finalizedBalance,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CashOutSheet(finalizedBalance: finalizedBalance),
  );
}

class CashOutSheet extends ConsumerStatefulWidget {
  const CashOutSheet({super.key, required this.finalizedBalance});

  final int finalizedBalance;

  @override
  ConsumerState<CashOutSheet> createState() => _CashOutSheetState();
}

class _CashOutSheetState extends ConsumerState<CashOutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  String _method = cashOutMethods.first;

  // Local, visual-only state for this sheet.
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await ref.read(requestCashOutProvider)(
        int.parse(_amount.text.trim()),
        _method,
        finalizedBalance: widget.finalizedBalance,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Failure catch (failure) {
      if (mounted) setState(() => _submitError = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _submitError = 'Could not send the request. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Lift the form above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cash out points', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Available: ${Formatters.points(widget.finalizedBalance)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Points to cash out',
                  suffixText: 'pts',
                ),
                validator: (value) =>
                    validateCashOutAmount(value, widget.finalizedBalance),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Send to', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final method in cashOutMethods)
                    ChoiceChip(
                      label: Text(method),
                      selected: method == _method,
                      onSelected: _submitting
                          ? null
                          : (_) => setState(() => _method = method),
                    ),
                ],
              ),
              if (_submitError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _submitError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Request cash out',
                onPressed: _submit,
                isLoading: _submitting,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
