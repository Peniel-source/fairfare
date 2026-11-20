import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../domain/entities/saved_route.dart';
import '../domain/saved_route_validation.dart';
import 'saved_route_providers.dart';

class SavedRouteSheet extends ConsumerStatefulWidget {
  const SavedRouteSheet({super.key, this.route});

  final SavedRoute? route;

  @override
  ConsumerState<SavedRouteSheet> createState() => _SavedRouteSheetState();
}

class _SavedRouteSheetState extends ConsumerState<SavedRouteSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _pickup;
  late final TextEditingController _dropoff;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.route?.label);
    _pickup = TextEditingController(text: widget.route?.fromArea);
    _dropoff = TextEditingController(text: widget.route?.toArea);
  }

  @override
  void dispose() {
    _label.dispose();
    _pickup.dispose();
    _dropoff.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final route = SavedRoute(
      id: widget.route?.id ?? '',
      fromArea: _pickup.text,
      toArea: _dropoff.text,
      label: _label.text,
    );
    try {
      if (widget.route == null) {
        await ref.read(addSavedRouteProvider).call(route);
      } else {
        await ref.read(updateSavedRouteProvider).call(route);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = savedRouteErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Form(
        key: _form,
        onChanged: () {
          if (_error != null) setState(() => _error = null);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.route == null ? 'Add saved route' : 'Edit saved route',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _label,
              enabled: !_saving,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Home to campus',
              ),
              validator: SavedRouteValidation.label,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _pickup,
              enabled: !_saving,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Pickup area'),
              validator: SavedRouteValidation.area,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _dropoff,
              enabled: !_saving,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Drop-off area',
                errorMaxLines: 3,
              ),
              validator: (value) =>
                  SavedRouteValidation.destination(value, _pickup.text),
              onFieldSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Save route',
              onPressed: _save,
              isLoading: _saving,
              expand: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancel',
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              variant: AppButtonVariant.text,
            ),
          ],
        ),
      ),
    ),
  );
}
