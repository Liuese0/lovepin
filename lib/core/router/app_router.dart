import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lovepin/core/constants/app_colors.dart';
import 'package:lovepin/features/auth/presentation/screens/login_screen.dart';
import 'package:lovepin/features/auth/presentation/screens/signup_screen.dart';
import 'package:lovepin/features/auth/providers/auth_provider.dart';
import 'package:lovepin/features/compose/presentation/screens/compose_screen.dart';
import 'package:lovepin/features/couple/presentation/screens/couple_link_screen.dart';
import 'package:lovepin/features/home/presentation/screens/home_screen.dart';
import 'package:lovepin/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:lovepin/features/settings/presentation/screens/settings_screen.dart';
import 'package:lovepin/features/splash/presentation/screens/splash_screen.dart';
import 'package:lovepin/features/widget_theme/presentation/screens/widget_theme_screen.dart';

/// Route path constants to avoid magic strings.
class RoutePaths {
  RoutePaths._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profileSetup = '/profile-setup';
  static const String coupleLink = '/couple-link';
  static const String home = '/home';
  static const String compose = '/compose';
  static const String settings = '/settings';
  static const String widgetTheme = '/widget-theme';
}

/// Route name constants.
class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String profileSetup = 'profile-setup';
  static const String coupleLink = 'couple-link';
  static const String home = 'home';
  static const String compose = 'compose';
  static const String settings = 'settings';
  static const String widgetTheme = 'widget-theme';
}

/// Navigator keys for the shell route.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Notifier that triggers GoRouter redirect re-evaluation when
/// auth or couple-link state changes, without recreating the router.
class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// The main GoRouter provider, scoped to Riverpod.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  // Listen (not watch) so the provider does NOT rebuild — the existing
  // GoRouter instance stays alive and only its redirect is re-evaluated.
  ref.listen(authStateProvider, (_, __) => refreshNotifier.notify());
  ref.listen(isCoupleLinkedProvider, (_, __) => refreshNotifier.notify());

  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authAsync = ref.read(authStateProvider);
      final isCoupleLinked = ref.read(isCoupleLinkedProvider);
      final isAuthenticated = authAsync.valueOrNull?.session != null;
      final currentPath = state.matchedLocation;

      // Allow splash screen to load without redirecting.
      if (currentPath == RoutePaths.splash) {
        return null;
      }

      // If the auth state is still loading, allow public paths through
      // so the splash bootstrap can navigate to login/signup.
      final publicPaths = {RoutePaths.login, RoutePaths.signup};
      if (authAsync.isLoading) {
        return publicPaths.contains(currentPath) ? null : RoutePaths.splash;
      }

      // Unauthenticated users may only visit login or signup.
      if (!isAuthenticated) {
        return publicPaths.contains(currentPath) ? null : RoutePaths.login;
      }

      // Authenticated users on public paths (login / signup):
      // Let the screen's own post-sign-in flow complete (profile check →
      // couple check → navigate).  If the router redirected here it would
      // race against the login screen and the couple-link check would
      // never run.
      if (publicPaths.contains(currentPath)) {
        return null;
      }

      // Authenticated but no couple link yet.
      if (!isCoupleLinked &&
          currentPath != RoutePaths.coupleLink &&
          currentPath != RoutePaths.profileSetup) {
        return RoutePaths.coupleLink;
      }

      return null;
    },
    routes: [
      // --- Standalone routes (outside shell) ---
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RoutePaths.profileSetup,
        name: RouteNames.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.coupleLink,
        name: RouteNames.coupleLink,
        builder: (context, state) => const CoupleLinkScreen(),
      ),
      GoRoute(
        path: RoutePaths.widgetTheme,
        name: RouteNames.widgetTheme,
        builder: (context, state) => const WidgetThemeScreen(),
      ),

      // --- Shell route with bottom navigation ---
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _ScaffoldWithBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: RoutePaths.home,
            name: RouteNames.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.compose,
            name: RouteNames.compose,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ComposeScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settings,
            name: RouteNames.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

/// A scaffold wrapper that provides a [BottomNavigationBar] for the shell
/// route's child screens.
class _ScaffoldWithBottomNav extends StatelessWidget {
  const _ScaffoldWithBottomNav({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_outlined),
            activeIcon: Icon(Icons.edit),
            label: 'Compose',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.compose)) return 1;
    if (location.startsWith(RoutePaths.settings)) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed(RouteNames.home);
        break;
      case 1:
        context.goNamed(RouteNames.compose);
        break;
      case 2:
        context.goNamed(RouteNames.settings);
        break;
    }
  }
}