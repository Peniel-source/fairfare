
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../../features/auth/presentation/auth_providers.dart';

/// Shows the passenger's display name in the app bar.
/// Falls back to a generic greeting when the profile is not yet loaded.
class ProfileGreeting extends ConsumerWidget {
  const ProfileGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passengerAsync = ref.watch(meProvider);
    //the name of the account that is signed in
    final accountName = ref.watch(authStateProvider).value?.displayName;

    return passengerAsync.when(
      loading: () => const Text('FairFare'),
      error: (_, _) => const Text('FairFare'),
      data: (passenger) {
        //use the account name when there is one, else the profile name
        final name = (accountName != null && accountName.isNotEmpty)
            ? accountName
            : passenger.displayName;
        final initials = Formatters.initials(name);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              child: Text(
                initials,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            const SizedBox(width: 8),
            Text('Hi, $name'),
          ],
        );
      },
    );
  }
}
