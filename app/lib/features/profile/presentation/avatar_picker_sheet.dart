// Bottom sheet where a passenger picks their avatar, grouped into Women and
// Men so they can choose the one that suits them. Nothing is preselected for
// a passenger who has not picked yet. The save state lives in
// ChooseAvatarController.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../domain/entities/avatar_preset.dart';
import 'profile_providers.dart';

/// Shows the picker. Returns true when a new avatar was saved.
Future<bool> showAvatarPicker(
  BuildContext context, {
  required String? currentAvatar,
  required String name,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) =>
        _AvatarPickerSheet(currentAvatar: currentAvatar, name: name),
  );
  return saved ?? false;
}

const _groupTitles = {AvatarGroup.women: 'Women', AvatarGroup.men: 'Men'};

class _AvatarPickerSheet extends ConsumerStatefulWidget {
  const _AvatarPickerSheet({required this.currentAvatar, required this.name});

  final String? currentAvatar;
  final String name;

  @override
  ConsumerState<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends ConsumerState<_AvatarPickerSheet> {
  late String? _selected = widget.currentAvatar;

  Future<void> _save() async {
    final id = _selected;
    if (id == null) return;
    final ok = await ref.read(chooseAvatarControllerProvider.notifier).save(id);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(chooseAvatarControllerProvider);
    final saving = state.isLoading;
    final changed = _selected != null && _selected != widget.currentAvatar;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your avatar',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Pick the one that suits you. It shows on your profile '
                    'and on the leaderboard.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  for (final group in AvatarGroup.values) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      _groupTitles[group]!.toUpperCase(),
                      style: AppTypography.eyebrow(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final (i, preset)
                            in avatarPresets
                                .where((p) => p.group == group)
                                .indexed)
                          _AvatarOption(
                            preset: preset,
                            label: '${_groupTitles[group]} avatar ${i + 1}',
                            name: widget.name,
                            selected: preset.id == _selected,
                            onTap: saving
                                ? null
                                : () => setState(() => _selected = preset.id),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.hasError) ...[
                  Text(
                    profileErrorMessage(state.error!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                FilledButton(
                  onPressed: changed && !saving ? _save : null,
                  child: Text(saving ? 'Saving…' : 'Save avatar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.preset,
    required this.label,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final AvatarPreset preset;
  final String label;
  final String name;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        key: ValueKey('avatar-${preset.id}'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 3,
              color: selected ? scheme.primary : Colors.transparent,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(avatar: preset.id, name: name, radius: 30),
              if (selected)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: scheme.primary,
                    child: Icon(Icons.check, size: 14, color: scheme.onPrimary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
