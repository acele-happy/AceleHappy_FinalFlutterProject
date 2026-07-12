import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/applications/applications_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/bookmarks/bookmarks_screen.dart';
import '../../features/home/discover_tab.dart';
import '../../features/home/home_shell.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/opportunities/create_opportunity_screen.dart';
import '../../features/opportunities/opportunity_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/startups/startup_detail_screen.dart';
import '../../features/startups/startup_profile_screen.dart';
import '../../providers/app_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoading = authState.isLoading || currentUser.isLoading;
      final user = currentUser.valueOrNull;
      final isLoggedIn = authState.valueOrNull != null;
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/splash';

      if (isLoading && location != '/splash') {
        return '/splash';
      }

      if (!isLoading && !isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (!isLoading && isLoggedIn && user != null) {
        if (!user.onboardingComplete && location != '/onboarding') {
          return '/onboarding';
        }
        if (user.onboardingComplete && isAuthRoute) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DiscoverTab()),
          ),
          GoRoute(
            path: '/applications',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ApplicationsScreen()),
          ),
          GoRoute(
            path: '/bookmarks',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BookmarksScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/opportunity/create',
        builder: (context, state) => const CreateOpportunityScreen(),
      ),
      GoRoute(
        path: '/opportunity/:id',
        builder: (context, state) => OpportunityDetailScreen(
          opportunityId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/startup/profile/edit',
        builder: (context, state) => const StartupProfileScreen(),
      ),
      GoRoute(
        path: '/startup/:id',
        builder: (context, state) => StartupDetailScreen(
          startupId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/application/:id',
        builder: (context, state) => ApplicationDetailScreen(
          applicationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});
