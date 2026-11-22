// The avatar a passenger picked, in a circle. Shows their initials when
// they have not picked one, while it loads, and if it cannot load (offline).
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/utils/formatters.dart';
import '../../features/profile/domain/entities/avatar_preset.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatar,
    required this.name,
    this.radius = 20,
  });

  /// Avatar id the passenger picked (avatarPresets), or null for none.
  final String? avatar;

  /// Display name, used for the initials fallback.
  final String name;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final initials = _Initials(name: name, radius: radius);
    final preset = avatarPresetById(avatar);

    return ExcludeSemantics(
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: preset == null
              ? initials
              : SvgPicture.network(
                  preset.url.toString(),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholderBuilder: (_) => initials,
                  errorBuilder: (_, _, _) => initials,
                ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge;

    return ColoredBox(
      color: scheme.surfaceContainer,
      child: Center(
        child: Text(
          Formatters.initials(name),
          style: style?.copyWith(
            fontSize: radius * 0.8,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
