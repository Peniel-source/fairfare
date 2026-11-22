//the pickup and dropoff fields. type an area and pick from the suggestions
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../domain/zone_finder.dart';

class RoutePicker extends StatelessWidget {
  const RoutePicker({
    super.key,
    required this.zones,
    required this.pickup,
    required this.dropoff,
    required this.onPickup,
    required this.onDropoff,
    required this.onSwap,
    required this.onUseLocation,
    required this.findingLocation,
  });

  final List<Zone> zones;
  final Zone? pickup;
  final Zone? dropoff;
  final void Function(Zone zone) onPickup;
  final void Function(Zone zone) onDropoff;
  final VoidCallback onSwap;
  final VoidCallback onUseLocation;
  final bool findingLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  ZoneSearchField(
                    label: 'Pickup',
                    zones: zones,
                    zone: pickup,
                    onPick: onPickup,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ZoneSearchField(
                    label: 'Dropoff',
                    zones: zones,
                    zone: dropoff,
                    onPick: onDropoff,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Swap pickup and dropoff',
              icon: const Icon(Icons.swap_vert),
              onPressed: onSwap,
            ),
          ],
        ),
        TextButton.icon(
          onPressed: findingLocation ? null : onUseLocation,
          icon: const Icon(Icons.my_location),
          label: Text(findingLocation ? 'Finding you...' : 'Use my location'),
        ),
      ],
    );
  }
}

//one field. the student types and the matching areas show under it
class ZoneSearchField extends StatelessWidget {
  const ZoneSearchField({
    super.key,
    required this.label,
    required this.zones,
    required this.zone,
    required this.onPick,
  });

  final String label;
  final List<Zone> zones;
  final Zone? zone;
  final void Function(Zone zone) onPick;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Zone>(
      //new key when the zone changes, so the field shows the new name after a swap or a chip tap
      key: ValueKey('$label-${zone?.id}'),
      initialValue: TextEditingValue(text: zone?.name ?? ''),
      displayStringForOption: (option) => option.name,
      optionsBuilder: (typed) {
        final text = typed.text.trim().toLowerCase();
        //show nothing until the student types
        if (text.isEmpty) return const Iterable<Zone>.empty();
        return zones.where(
          (option) => option.name.toLowerCase().contains(text),
        );
      },
      onSelected: onPick,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Type an area',
          ),
        );
      },
    );
  }
}
