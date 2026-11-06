/// Every route path in one place, so screens never type a path by hand.
class Routes {
  Routes._();

  static const splash = '/splash';

  // Signed out.
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';

  // Account gates.
  static const verifyEmail = '/verify-email';
  static const awaitingApproval = '/awaiting-approval';
  static const accountProblem = '/account-problem';

  // Student.
  static const home = '/home';
  static const reports = '/reports';
  static const newReport = '/reports/new';
  static const notifications = '/notifications';
  static const profile = '/profile';

  /// Report details and "Report submitted" sit above the tabs (no nav bar).
  static const reportBase = '/report';
  static const reportDetailsPattern = '$reportBase/:id';
  static const reportSubmittedPattern = '$reportBase/:id/submitted';
  static String reportDetails(String id) => '$reportBase/$id';
  static String reportSubmitted(String id) => '$reportBase/$id/submitted';

  // Staff.
  static const staffDashboard = '/staff';
  static const staffReports = '/staff/reports';
  static const staffProfile = '/staff/profile';

  /// "Review and update" sits above the staff tabs (no nav bar).
  static const staffReviewPattern = '/staff/report/:id';
  static String staffReview(String id) => '/staff/report/$id';

  // Debug builds only.
  static const gallery = '/debug/gallery';

  static const signedOutRoutes = {onboarding, signIn, signUp};
  static const studentAreas = [
    home,
    reports,
    notifications,
    profile,
    reportBase,
  ];
  static const staffAreas = [staffDashboard];
}
