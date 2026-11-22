// App bar shared by the four home tabs: greeting on the left, avatar on the
// right that opens Profile (Profile links on to Settings).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/profile/presentation/profile_providers.dart';
import 'profile_greeting.dart';
import 'user_avatar.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const ProfileGreeting(),
      actions: [
        IconButton(
          tooltip: 'Profile',
          icon: const _MyAvatar(),
          onPressed: () => context.push('/profile'),
        ),
      ],
    );
  }
}

/// The avatar the passenger picked (initials if none), or a person icon until
/// the profile loads.
class _MyAvatar extends ConsumerWidget {
  const _MyAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).valueOrNull;
    if (me == null) return const CircleAvatar(child: Icon(Icons.person));
    return UserAvatar(avatar: me.avatar, name: me.displayName);
  }
}
