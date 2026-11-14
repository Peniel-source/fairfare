// App bar shared by the four home tabs: greeting on the left, avatar on the
// right that opens Profile (Profile links on to Settings).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'profile_greeting.dart';

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
          icon: const CircleAvatar(child: Icon(Icons.person)),
          onPressed: () => context.push('/profile'),
        ),
      ],
    );
  }
}
