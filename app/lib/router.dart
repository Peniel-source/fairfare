import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/auth_providers.dart';
import 'shared/widgets/profile_greeting.dart';

/// Top-level navigator key for GoRouter.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes that do not require authentication.
const kPublicRoutes = {'/', '/login', '/register', '/reset-password'};

/// Routes that redirect a signed-in user away from them.
const kAuthOnlyRoutes = {'/', '/login', '/register'};

/// The app's router configuration.
///
/// Routes:
///  /              → Landing (signed out)
///  /login         → Login
///  /register      → Register
///  /reset-password→ Reset Password
///  /verify-email  → Verify Email
///  /home          → Home shell with 4 tabs
///  /home/corridors→ Corridors (tab 0)
///  /home/report   → Report (tab 1)
///  /home/pass     → Pass (tab 2)
///  /home/wallet   → Wallet (tab 3)
///  /saved-routes  → Saved Routes
///  /my-reports    → My Reports
///  /profile       → Profile
///  /settings      → Settings
///
/// Auth redirects are driven by the auth state stream from [authStateProvider].
/// Each screen owner replaces their placeholder screen.
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    // Read auth state from the Riverpod provider tree attached to this context.
    final container = ProviderScope.containerOf(context, listen: false);
    final authAsyncValue = container.read(authStateProvider);
    final user = authAsyncValue.value;

    // If we don't know the auth state yet, stay on the current page.
    if (authAsyncValue.isLoading || user == null) {
      // Not signed in yet — allow public routes only.
      if (!kPublicRoutes.contains(state.matchedLocation)) {
        return '/';
      }
      return null;
    }

    // Signed in with unverified email → verify screen.
    if (!user.emailVerified) {
      return '/verify-email';
    }

    // Signed in — block auth-only routes.
    if (kAuthOnlyRoutes.contains(state.matchedLocation)) {
      return '/home/corridors';
    }

    return null;
  },
  routes: [
    // Authenticated home shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) {
        return _HomeShell(state: state, child: child);
      },
      routes: [
        GoRoute(
          path: '/home/corridors',
          name: 'corridors',
          builder: (context, state) =>
              const _PlaceholderScreen(title: 'Corridors'),
        ),
        GoRoute(
          path: '/home/report',
          name: 'report',
          builder: (context, state) =>
              const _PlaceholderScreen(title: 'Report'),
        ),
        GoRoute(
          path: '/home/pass',
          name: 'pass',
          builder: (context, state) => const _PlaceholderScreen(title: 'Pass'),
        ),
        GoRoute(
          path: '/home/wallet',
          name: 'wallet',
          builder: (context, state) =>
              const _PlaceholderScreen(title: 'Wallet'),
        ),
      ],
    ),
    // Standalone routes
    GoRoute(
      path: '/',
      name: 'landing',
      builder: (context, state) => const _PlaceholderScreen(title: 'Landing'),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const _PlaceholderScreen(title: 'Login'),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const _PlaceholderScreen(title: 'Register'),
    ),
    GoRoute(
      path: '/reset-password',
      name: 'resetPassword',
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Reset Password'),
    ),
    GoRoute(
      path: '/verify-email',
      name: 'verifyEmail',
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Verify Email'),
    ),
    GoRoute(
      path: '/saved-routes',
      name: 'savedRoutes',
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Saved Routes'),
    ),
    GoRoute(
      path: '/my-reports',
      name: 'myReports',
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'My Reports'),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const _PlaceholderScreen(title: 'Profile'),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const _PlaceholderScreen(title: 'Settings'),
    ),
  ],
);

/// Home shell with bottom navigation bar (4 tabs).
class _HomeShell extends StatefulWidget {
  final Widget child;
  final GoRouterState state;

  const _HomeShell({required this.child, required this.state});

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int get _currentIndex {
    final path = widget.state.matchedLocation;
    if (path.contains('/corridors')) return 0;
    if (path.contains('/report')) return 1;
    if (path.contains('/pass')) return 2;
    if (path.contains('/wallet')) return 3;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/home/corridors');
      case 1:
        context.go('/home/report');
      case 2:
        context.go('/home/pass');
      case 3:
        context.go('/home/wallet');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Corridors',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_membership_outlined),
            selectedIcon: Icon(Icons.card_membership),
            label: 'Pass',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }
}

/// Placeholder screen for each route. Each screen owner replaces this.
class _PlaceholderScreen extends ConsumerWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const ProfileGreeting(),
        actions: [
          // Avatar icon opens Profile and Settings
          IconButton(
            icon: const CircleAvatar(child: Icon(Icons.person)),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Center(child: Text('$title — coming soon')),
    );
  }
}
