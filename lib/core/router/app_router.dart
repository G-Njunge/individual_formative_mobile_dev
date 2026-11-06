import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/account_gate_screens.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/onboarding/application/onboarding_provider.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/reports/presentation/browse_reports_screen.dart';
import '../../features/reports/presentation/home_screen.dart';
import '../../features/reports/presentation/new_report_screen.dart';
import '../../features/reports/presentation/report_details_screen.dart';
import '../../features/reports/presentation/report_submitted_screen.dart';
import '../../features/notifications/application/notification_providers.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_pages.dart';
import '../../features/profile/presentation/staff_profile_screen.dart';
import '../../features/profile/presentation/student_profile_screen.dart';
import '../../features/staff/presentation/review_update_screen.dart';
import '../../features/staff/presentation/staff_dashboard_screen.dart';
import '../../features/staff/presentation/staff_reports_screen.dart';
import '../debug/component_gallery_screen.dart';
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
        builder: (_, _, shell) => Consumer(
          builder: (_, ref, _) => StudentShell(
            shell: shell,
            hasUnread: ref.watch(hasUnreadNotificationsProvider),
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.reports,
                builder: (_, _) => const BrowseReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.notifications,
                builder: (_, _) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const StudentProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'followed',
                    builder: (_, _) => const FollowedReportsScreen(),
                  ),
                  GoRoute(
                    path: 'notification-settings',
                    builder: (_, _) => const NotificationSettingsScreen(),
                  ),
                  GoRoute(path: 'help', builder: (_, _) => const HelpScreen()),
                ],
              ),
            ],
          ),
        ],
      ),
      // Full-screen pages above the student tabs.
      GoRoute(
        path: Routes.newReport,
        builder: (_, _) => const NewReportScreen(),
      ),
      GoRoute(
        path: Routes.reportDetailsPattern,
        builder: (_, state) =>
            ReportDetailsScreen(reportId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.reportSubmittedPattern,
        builder: (_, state) =>
            ReportSubmittedScreen(reportId: state.pathParameters['id']!),
      ),

      // Staff area.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => StaffShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.staffDashboard,
                builder: (_, _) => const StaffDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.staffReports,
                builder: (_, _) => const StaffReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.staffProfile,
                builder: (_, _) => const StaffProfileScreen(),
                routes: [
                  GoRoute(path: 'help', builder: (_, _) => const HelpScreen()),
                ],
              ),
            ],
          ),
        ],
      ),

      // Full-screen page above the staff tabs.
      GoRoute(
        path: Routes.staffReviewPattern,
        builder: (_, state) =>
            ReviewUpdateScreen(reportId: state.pathParameters['id']!),
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
