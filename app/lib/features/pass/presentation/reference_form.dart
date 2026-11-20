// Payment reference entry. Validation comes from the domain layer; the
// submit state lives in SubmitReferenceController, not in this widget.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../domain/payment_reference.dart';
import 'pass_providers.dart';

class ReferenceForm extends ConsumerStatefulWidget {
  const ReferenceForm({super.key});

  @override
  ConsumerState<ReferenceForm> createState() => _ReferenceFormState();
}

class _ReferenceFormState extends ConsumerState<ReferenceForm> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(submitReferenceControllerProvider.notifier)
        .submit(_controller.text);
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reference sent. We are checking it')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submit = ref.watch(submitReferenceControllerProvider);
    final sending = submit.isLoading;
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Payment reference', style: text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _controller,
                enabled: !sending,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                maxLength: kMaxReferenceLength,
                decoration: InputDecoration(
                  labelText: 'Reference from your SMS',
                  hintText: 'e.g. 1234567890',
                  border: const OutlineInputBorder(),
                  errorText: submit.hasError
                      ? passErrorMessage(submit.error!)
                      : null,
                ),
                validator: validatePaymentReference,
                // Typing again clears a server error such as "already used".
                onChanged: (_) {
                  if (submit.hasError) {
                    ref.invalidate(submitReferenceControllerProvider);
                  }
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: sending ? null : _submit,
                child: sending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
