import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:individual_formative/core/firebase/firebase_providers.dart';
import 'package:individual_formative/core/theme/app_theme.dart';
import 'package:individual_formative/features/auth/presentation/sign_up_screen.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore db;

  setUp(() {
    auth = MockFirebaseAuth();
    db = FakeFirebaseFirestore();
  });

  Future<void> pumpSignUp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1100 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const SignUpScreen())],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firestoreProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is Column),
  );

  Future<void> type(WidgetTester tester, String label, String text) async {
    final input = find.descendant(
      of: field(label).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(input.first, text);
    await tester.pump();
  }

  testWidgets('the password checklist ticks off while typing', (tester) async {
    await pumpSignUp(tester);
    expect(
      find.bySemanticsLabel('At least 8 characters: not yet'),
      findsOneWidget,
    );

    await type(tester, 'Password', 'campus2026');
    expect(
      find.bySemanticsLabel('At least 8 characters: done'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('A number (0-9): done'), findsOneWidget);
    expect(
      find.bySemanticsLabel('An uppercase letter (A-Z): not yet'),
      findsOneWidget,
    );
  });

  testWidgets('says exactly what a weak password is missing', (tester) async {
    await pumpSignUp(tester);
    await type(tester, 'Password', 'campus2026');
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle();
    expect(find.text('Add an uppercase letter and a symbol'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('creates the account and profile when everything is valid', (
    tester,
  ) async {
    await pumpSignUp(tester);
    await type(tester, 'Full name', 'Amani Mugisha');
    await type(tester, 'Campus email', 'a.mugisha@alustudent.com');
    await type(tester, 'Password', 'Campus-2026');
    await type(tester, 'Confirm password', 'Campus-2026');
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle();

    final user = auth.currentUser;
    expect(user, isNotNull);
    final profile = (await db.doc('users/${user!.uid}').get()).data()!;
    expect(profile['role'], 'student');
    expect(profile['name'], 'Amani Mugisha');
  });

  testWidgets('a student email is refused for a staff account', (tester) async {
    await pumpSignUp(tester);
    await tester.tap(find.text('Campus staff'));
    await tester.pumpAndSettle();
    await type(tester, 'Campus email', 'a.mugisha@alustudent.com');
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Use your campus email (@alueducation.com)'),
      findsOneWidget,
    );
  });
}
