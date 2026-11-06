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

  // Staff.
  static const staffDashboard = '/staff';
  static const staffReports = '/staff/reports';
  static const staffProfile = '/staff/profile';

  // Debug builds only.
  static const gallery = '/debug/gallery';

  static const signedOutRoutes = {onboarding, signIn, signUp};
  static const studentAreas = [home, reports, notifications, profile];
  static const staffAreas = [staffDashboard];
}
