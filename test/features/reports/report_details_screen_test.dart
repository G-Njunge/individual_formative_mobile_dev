import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:individual_formative/core/firebase/firebase_providers.dart';
import 'package:individual_formative/core/theme/app_theme.dart';
import 'package:individual_formative/features/reports/application/report_providers.dart';
import 'package:individual_formative/features/reports/presentation/report_details_screen.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await db.doc('reports/r1').set({
      'ticketNumber': 1042,
      'title': 'Leaking tap in the Block C washroom',
      'description': 'Spraying water.',
      'category': 'water',
      'location': 'Block C',
      'urgency': 'medium',
      'status': 'in_progress',
      'reporterId': 'u1',
      'reporterName': 'Amani Mugisha',
      'anonymous': false,
      'photoCount': 0,
      'assignedTo': null,
      'meTooCount': 12,
    });
  });

  Future<void> pumpDetails(WidgetTester tester, {required String uid}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const ReportDetailsScreen(reportId: 'r1'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          currentUidProvider.overrideWithValue(uid),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Me too adds support, and taking it back asks first', (
    tester,
  ) async {
    await pumpDetails(tester, uid: 'u2');
    await scrollTo(tester, find.text('Me too'));
    expect(find.text('12 students'), findsOneWidget);

    await tester.tap(find.text('Me too'));
    await tester.pumpAndSettle();
    expect(find.text('Added'), findsOneWidget);
    expect(find.text('13 students'), findsOneWidget);
    expect((await db.doc('reports/r1/supporters/u2').get()).exists, isTrue);

    // Tapping "Added" asks before removing anything.
    await tester.tap(find.text('Added'));
    await tester.pumpAndSettle();
    expect(find.text('Remove your support?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect((await db.doc('reports/r1').get()).data()!['meTooCount'], 13);

    await tester.tap(find.text('Added'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove my support'));
    await tester.pumpAndSettle();
    expect(find.text('Me too'), findsOneWidget);
    expect((await db.doc('reports/r1').get()).data()!['meTooCount'], 12);
    expect((await db.doc('reports/r1/supporters/u2').get()).exists, isFalse);
  });

  testWidgets('the reporter sees no Me too button on their own report', (
    tester,
  ) async {
    await pumpDetails(tester, uid: 'u1');
    await scrollTo(tester, find.text('12 students'));
    expect(find.text('Me too'), findsNothing);
  });

  testWidgets('the reporter is asked "Is it fixed?" and can reopen', (
    tester,
  ) async {
    await db.doc('reports/r1').update({'status': 'resolved'});
    await pumpDetails(tester, uid: 'u1');
    await scrollTo(tester, find.text('Is it fixed?'));

    await tester.tap(find.text('Reopen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reopen report'));
    await tester.pumpAndSettle();
    expect(find.text("Say what's still wrong"), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Still dripping');
    await tester.tap(find.text('Reopen report'));
    await tester.pumpAndSettle();

    final saved = (await db.doc('reports/r1').get()).data()!;
    expect(saved['status'], 'submitted');
    expect(find.text('Is it fixed?'), findsNothing);
  });

  testWidgets('"Yes, fixed" confirms the fix', (tester) async {
    await db.doc('reports/r1').update({'status': 'resolved'});
    await pumpDetails(tester, uid: 'u1');
    await scrollTo(tester, find.text('Yes, fixed'));
    await tester.tap(find.text('Yes, fixed'));
    await tester.pumpAndSettle();

    expect((await db.doc('reports/r1').get()).data()!['confirmed'], isTrue);
    expect(find.text('Is it fixed?'), findsNothing);
    expect(find.text('You confirmed it is fixed. Thank you.'), findsOneWidget);
  });
}
