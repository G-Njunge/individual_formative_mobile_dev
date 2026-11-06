import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/router/routes.dart';
import 'package:individual_formative/core/router/session_redirect.dart';
import 'package:individual_formative/features/auth/application/auth_providers.dart';

String? go(
  SessionStatus status,
  String location, {
  bool onboardingSeen = true,
  bool authBusy = false,
}) => sessionRedirect(
  status: status,
  onboardingSeen: onboardingSeen,
  location: location,
  authBusy: authBusy,
);

void main() {
  test('waits on the splash screen while loading', () {
    expect(go(SessionStatus.loading, Routes.home), Routes.splash);
    expect(go(SessionStatus.loading, Routes.splash), isNull);
  });

  group('signed out', () {
    test('first launch shows onboarding', () {
      expect(
        go(SessionStatus.signedOut, Routes.splash, onboardingSeen: false),
        Routes.onboarding,
      );
    });

    test('after onboarding goes to sign in', () {
      expect(go(SessionStatus.signedOut, Routes.splash), Routes.signIn);
      expect(go(SessionStatus.signedOut, Routes.home), Routes.signIn);
    });

    test('may move between the signed-out pages', () {
      for (final page in Routes.signedOutRoutes) {
        expect(go(SessionStatus.signedOut, page), isNull);
      }
    });
  });

  test('unverified accounts are held on Check your email', () {
    expect(
      go(SessionStatus.needsVerification, Routes.home),
      Routes.verifyEmail,
    );
    expect(go(SessionStatus.needsVerification, Routes.verifyEmail), isNull);
  });

  test('unapproved staff wait for approval', () {
    expect(
      go(SessionStatus.awaitingApproval, Routes.staffDashboard),
      Routes.awaitingApproval,
    );
  });

  test('a missing profile shows the account problem page', () {
    expect(
      go(SessionStatus.missingProfile, Routes.home),
      Routes.accountProblem,
    );
  });

  group('students', () {
    test('land on Home and may use student pages', () {
      expect(go(SessionStatus.student, Routes.signIn), Routes.home);
      expect(go(SessionStatus.student, Routes.reports), isNull);
      expect(go(SessionStatus.student, Routes.newReport), isNull);
      expect(go(SessionStatus.student, Routes.profile), isNull);
    });

    test('cannot open staff pages', () {
      expect(go(SessionStatus.student, Routes.staffDashboard), Routes.home);
      expect(go(SessionStatus.student, Routes.staffReports), Routes.home);
    });
  });

  group('approved staff', () {
    test('land on the dashboard and stay in the staff area', () {
      expect(go(SessionStatus.staff, Routes.signIn), Routes.staffDashboard);
      expect(go(SessionStatus.staff, Routes.staffReports), isNull);
      expect(go(SessionStatus.staff, Routes.home), Routes.staffDashboard);
    });
  });

  test('no redirects while sign in is still checking the account', () {
    expect(go(SessionStatus.student, Routes.signIn, authBusy: true), isNull);
  });

  test('debug routes only when allowed', () {
    expect(go(SessionStatus.student, Routes.gallery), Routes.home);
    expect(
      sessionRedirect(
        status: SessionStatus.student,
        onboardingSeen: true,
        location: Routes.gallery,
        allowDebugRoutes: true,
      ),
      isNull,
    );
  });
}
