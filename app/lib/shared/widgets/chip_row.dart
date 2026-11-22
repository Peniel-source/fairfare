//this creates a row of corridor chips that you can scroll sideways
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../features/corridors/domain/entities/corridor.dart';

class ChipRow extends StatelessWidget {
  const ChipRow({
    super.key,
    required this.corridors,
    required this.onPick,
    this.selectedId,
  });

  final List<Corridor> corridors;
  final String? selectedId;
  final void Function(Corridor corridor) onPick;

  @override
  Widget build(BuildContext context) {
    if (corridors.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: AppSpacing.minTapTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: corridors.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final corridor = corridors[index];
          return ChoiceChip(
            label: Text('${corridor.fromArea} to ${corridor.toArea}'),
            selected: corridor.id == selectedId,
            onSelected: (_) => onPick(corridor),
          );
        },
      ),
    );
  }
}