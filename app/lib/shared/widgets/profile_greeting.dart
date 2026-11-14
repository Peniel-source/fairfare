// Reference slice: a small greeting widget that demonstrates the full
// Clean Architecture data flow.
//
// Data flow:
//   Rider entity → ProfileRepository interface → FakeProfileRepository
//   → profile_providers.dart (meProvider) → this widget
//
// This is the example documented in docs/architecture_pattern.md.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/presentation/profile_providers.dart';

/// Shows the rider's display name in the app bar.
/// Falls back to a generic greeting when the profile is not yet loaded.
class ProfileGreeting extends ConsumerWidget {
  const ProfileGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riderAsync = ref.watch(meProvider);

    return riderAsync.when(
      loading: () => const Text('FairFare'),
      error: (_, _) => const Text('FairFare'),
      data: (rider) {
        // Extract initials for the avatar.
        final initials = _getInitials(rider.displayName);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              child: Text(initials, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Text('Hi, ${rider.displayName}'),
          ],
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}
