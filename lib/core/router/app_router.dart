import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/account_gate_screens.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/onboarding/application/onboarding_provider.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../debug/component_gallery_screen.dart';
import '../debug/placeholder_screen.dart';
import 'routes.dart';
import 'session_redirect.dart';
import 'shells.dart';

/// The app's routes. Whenever the session changes (sign in, verification,
/// approval, sign out) the router re-runs [sessionRedirect], so screens never
/// navigate after auth events themselves.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RefreshSignal();
  ref.listen(sessionProvider, (_, _) => refresh.ping());
  ref.listen(onboardingSeenProvider, (_, _) => refresh.ping());
  ref.listen(authBusyProvider, (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => sessionRedirect(
      status: ref.read(sessionProvider).status,
      onboardingSeen: ref.read(onboardingSeenProvider),
      location: state.matchedLocation,
      authBusy: ref.read(authBusyProvider),
      allowDebugRoutes: kDebugMode,
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(
        path: Routes.verifyEmail,
        builder: (_, _) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: Routes.awaitingApproval,
        builder: (_, _) => const AwaitingApprovalScreen(),
      ),
      GoRoute(
        path: Routes.accountProblem,
        builder: (_, _) => const AccountProblemScreen(),
      ),

      // Student area, with the floating nav bar.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => StudentShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, _) =>
                    const PlaceholderScreen(title: 'Home', milestone: 3),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.reports,
                builder: (_, _) => const PlaceholderScreen(
                  title: 'Campus reports',
                  milestone: 3,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.notifications,
                builder: (_, _) => const PlaceholderScreen(
                  title: 'Notifications',
                  milestone: 5,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const PlaceholderScreen(
                  title: 'Profile',
                  milestone: 5,
                  showAccount: true,
                ),
              ),
            ],
          ),
        ],
      ),
      // Full-screen pages above the student tabs.
      GoRoute(
        path: Routes.newReport,
        builder: (_, _) => const PlaceholderScreen(
          title: 'New report',
          milestone: 3,
          closable: true,
        ),
      ),

      // Staff area.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => StaffShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.staffDashboard,
                builder: (_, _) => const PlaceholderScreen(
                  title: 'Facilities desk',
                  milestone: 4,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.staffReports,
                builder: (_, _) =>
                    const PlaceholderScreen(title: 'All reports', milestone: 4),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.staffProfile,
                builder: (_, _) => const PlaceholderScreen(
                  title: 'Profile',
                  milestone: 5,
                  showAccount: true,
                ),
              ),
            ],
          ),
        ],
      ),

      if (kDebugMode)
        GoRoute(
          path: Routes.gallery,
          builder: (_, _) => const ComponentGalleryScreen(),
        ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _RefreshSignal extends ChangeNotifier {
  void ping() => notifyListeners();
}
