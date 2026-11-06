import '../../features/auth/application/auth_providers.dart';
import 'routes.dart';

/// Decides where someone may go, given who they are. Returns the path to
/// send them to, or null to let them through.
///
/// It is a plain function with no Flutter or Firebase in it, so every rule
/// below is unit tested in `test/core/router/session_redirect_test.dart`.
String? sessionRedirect({
  required SessionStatus status,
  required bool onboardingSeen,
  required String location,
  bool authBusy = false,
  bool allowDebugRoutes = false,
}) {
  // Sign in or sign up is still running its own checks; stay put.
  if (authBusy) return null;
  if (allowDebugRoutes && location.startsWith('/debug')) return null;

  bool inArea(List<String> areas) =>
      areas.any((a) => location == a || location.startsWith('$a/'));

  String? only(String path) => location == path ? null : path;

  switch (status) {
    case SessionStatus.loading:
      return only(Routes.splash);

    case SessionStatus.signedOut:
      if (Routes.signedOutRoutes.contains(location)) return null;
      return onboardingSeen ? Routes.signIn : Routes.onboarding;

    case SessionStatus.needsVerification:
      return only(Routes.verifyEmail);

    case SessionStatus.awaitingApproval:
      return only(Routes.awaitingApproval);

    case SessionStatus.missingProfile:
      return only(Routes.accountProblem);

    case SessionStatus.student:
      return inArea(Routes.studentAreas) ? null : Routes.home;

    case SessionStatus.staff:
      return inArea(Routes.staffAreas) ? null : Routes.staffDashboard;
  }
}
