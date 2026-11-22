// Dialog to change the display name. Validation comes from the domain layer;
// the save state lives in EditDisplayNameController.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/display_name.dart';
import 'profile_providers.dart';

/// Shows the dialog. Returns true when the name was saved.
Future<bool> showEditDisplayNameDialog(
  BuildContext context, {
  required String currentName,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _EditDisplayNameDialog(currentName: currentName),
  );
  return saved ?? false;
}

class _EditDisplayNameDialog extends ConsumerStatefulWidget {
  const _EditDisplayNameDialog({required this.currentName});

  final String currentName;

  @override
  ConsumerState<_EditDisplayNameDialog> createState() =>
      _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState
    extends ConsumerState<_EditDisplayNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(editDisplayNameControllerProvider.notifier)
        .save(_controller.text);
    // Close only if the dialog is still open: if the passenger already
    // closed it, popping again would close the screen underneath.
    if (ok && mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editDisplayNameControllerProvider);
    final saving = state.isLoading;

    return AlertDialog(
      title: const Text('Edit display name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          enabled: !saving,
          maxLength: kMaxDisplayNameLength,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Display name',
            helperText: 'Shown on the leaderboard',
            errorText: state.hasError
                ? profileErrorMessage(state.error!)
                : null,
          ),
          validator: validateDisplayName,
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
