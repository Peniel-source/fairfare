// Reference slice: a small greeting widget that demonstrates the full
// Clean Architecture data flow.
//
// Data flow:
//   Passenger entity → ProfileRepository interface → ProfileRepositoryImpl
//   → profile_providers.dart (meProvider) → this widget
//
// How to add a feature the same way (the architecture pattern):
//   1. Entity      features/<f>/domain/entities/   plain Dart, no Flutter or
//                  Firebase imports.
//   2. Interface   features/<f>/domain/repositories/   abstract class; the
//                  signed-in passenger id is resolved inside the repository.
//   3. Fake        features/<f>/data/fake_<f>_repository.dart   in-memory
//                  sample data, used until the Firestore implementation exists.
//   4. Provider    features/<f>/presentation/<f>_providers.dart   returns the
//                  fake or the real repository based on AppConstants.useFakeData.
//   5. Widget      a ConsumerWidget that ref.watch()es the provider and handles
//                  loading, error and data. No business logic and no Firestore
//                  calls in the widget.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../features/profile/presentation/profile_providers.dart';

/// Shows the passenger's display name in the app bar.
/// Falls back to a generic greeting when the profile is not yet loaded.
class ProfileGreeting extends ConsumerWidget {
  const ProfileGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passengerAsync = ref.watch(meProvider);

    return passengerAsync.when(
      loading: () => const Text('FairFare'),
      error: (_, _) => const Text('FairFare'),
      data: (passenger) {
        final initials = Formatters.initials(passenger.displayName);
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
            Text('Hi, ${passenger.displayName}'),
          ],
        );
      },
    );
  }
}
