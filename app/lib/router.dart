import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/domain/entities/auth_user.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/pass/presentation/pass_screen.dart';
import 'features/report/presentation/report_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/wallet/presentation/wallet_screen.dart';
import 'shared/widgets/home_app_bar.dart';

/// Top-level navigator key for GoRouter.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes that do not require authentication.
const kPublicRoutes = {'/', '/login', '/register', '/reset-password'};

/// Routes that redirect a signed-in user away from them.
const kAuthOnlyRoutes = {'/', '/login', '/register'};

/// Where a signed-in, verified passenger lands.
const kHomeRoute = '/home/corridors';

/// Where a signed-in passenger with an unverified email is held.
const kVerifyEmailRoute = '/verify-email';

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
/// The router listens to that provider through [refreshListenable], so the
/// redirect re-runs on every sign in, sign out and email verification.
/// Each screen owner replaces their placeholder screen.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(ref.read(authStateProvider), state.matchedLocation),
    routes: _routes,
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Pure redirect rule, kept out of the router so it can be unit tested (E6).
///
/// Returns the location to redirect to, or null to stay.
///  - auth state still loading: stay put
///  - signed out: public routes only, everything else goes to Landing
///  - signed in, email not verified: Verify Email only
///  - signed in and verified: auth screens and Verify Email go to Corridors
String? authRedirect(AsyncValue<AuthUser?> auth, String location) {
  if (auth.isLoading && !auth.hasValue) return null;

  final user = auth.value;
  if (user == null) {
    return kPublicRoutes.contains(location) ? null : '/';
  }

  if (!user.emailVerified) {
    return location == kVerifyEmailRoute ? null : kVerifyEmailRoute;
  }

  if (kAuthOnlyRoutes.contains(location) || location == kVerifyEmailRoute) {
    return kHomeRoute;
  }
  return null;
}

final _routes = <RouteBase>[
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
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/home/pass',
        name: 'pass',
        builder: (context, state) => const PassScreen(),
      ),
      GoRoute(
        path: '/home/wallet',
        name: 'wallet',
        builder: (context, state) => const WalletScreen(),
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
    builder: (context, state) => const _PlaceholderScreen(title: 'My Reports'),
  ),
  GoRoute(
    path: '/profile',
    name: 'profile',
    builder: (context, state) => const _PlaceholderScreen(title: 'Profile'),
  ),
  GoRoute(
    path: '/settings',
    name: 'settings',
    builder: (context, state) => const SettingsScreen(),
  ),
];

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
      appBar: const HomeAppBar(),
      body: Center(child: Text('$title — coming soon')),
    );
  }
}
