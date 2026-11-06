import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:individual_formative/core/firebase/firebase_providers.dart';
import 'package:individual_formative/core/theme/app_theme.dart';
import 'package:individual_formative/core/widgets/stat_tile.dart';
import 'package:individual_formative/features/auth/application/auth_providers.dart';
import 'package:individual_formative/features/auth/data/app_user.dart';
import 'package:individual_formative/features/reports/application/report_providers.dart';
import 'package:individual_formative/features/reports/presentation/browse_reports_screen.dart';
import 'package:individual_formative/features/staff/application/staff_providers.dart';
import 'package:individual_formative/features/staff/presentation/staff_dashboard_screen.dart';

const jean = AppUser(
  uid: 's1',
  name: 'Jean Habimana',
  email: 'jean.h@alueducation.com',
  role: UserRole.staff,
  approved: true,
);

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    // Minutes, not hours, so "New today" doesn't depend on when the test
    // runs (a report from 3 hours ago is yesterday's just after midnight).
    final now = DateTime.now();
    final rows = [
      (
        'Leaking tap in Block C',
        'Block C',
        'in_progress',
        'medium',
        'u1',
        's1',
        2,
      ),
      (
        'Streetlight out on the main path',
        'Main path',
        'submitted',
        'high',
        'u2',
        null,
        1,
      ),
      (
        'Broken chair in Room 204',
        'Room 204',
        'resolved',
        'low',
        'u1',
        's1',
        30,
      ),
      (
        'Power out in the library',
        'Library L2',
        'submitted',
        'high',
        'u3',
        null,
        3,
      ),
    ];
    for (final (i, (title, place, status, urgency, by, assignee, hours))
        in rows.indexed) {
      await db.doc('reports/r$i').set({
        'ticketNumber': 1040 + i,
        'title': title,
        'description': '',
        'category': 'water',
        'location': place,
        'urgency': urgency,
        'status': status,
        'reporterId': by,
        'reporterName': 'Someone',
        'anonymous': false,
        'photoCount': 0,
        'assignedTo': assignee == null
            ? null
            : {'uid': assignee, 'name': 'Jean Habimana'},
        'meTooCount': i,
        'createdAt': Timestamp.fromDate(now.subtract(Duration(minutes: hours))),
        'updatedAt': Timestamp.fromDate(now.subtract(Duration(minutes: hours))),
      });
    }
  });

  Future<void> pump(WidgetTester tester, Widget screen, List overrides) async {
    tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => screen)],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [firestoreProvider.overrideWithValue(db), ...overrides],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Browse', () {
    Future<void> pumpBrowse(WidgetTester tester) => pump(
      tester,
      const BrowseReportsScreen(),
      [currentUidProvider.overrideWithValue('u1')],
    );

    testWidgets('search, status chips and My reports narrow the list', (
      tester,
    ) async {
      await pumpBrowse(tester);
      expect(find.text('4 reports'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'block c');
      await tester.pumpAndSettle();
      expect(find.text('1 report'), findsOneWidget);
      expect(find.text('Leaking tap in Block C'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Submitted').first);
      await tester.pumpAndSettle();
      expect(find.text('2 reports'), findsOneWidget);

      await tester.tap(find.text('All').first);
      await tester.tap(find.text('My reports'));
      await tester.pumpAndSettle();
      expect(find.text('2 reports'), findsOneWidget);
      expect(find.text('Broken chair in Room 204'), findsOneWidget);
      expect(find.text('Power out in the library'), findsNothing);
    });

    testWidgets('a search with no results says so', (tester) async {
      await pumpBrowse(tester);
      await tester.enterText(find.byType(TextField), 'swimming pool');
      await tester.pumpAndSettle();
      expect(find.text('No matching reports'), findsOneWidget);
    });
  });

  testWidgets('staff dashboard counts and queues', (tester) async {
    await pump(tester, const StaffDashboardScreen(), [
      sessionProvider.overrideWithValue(
        const Session(SessionStatus.staff, profile: jean),
      ),
      currentUidProvider.overrideWithValue('s1'),
      staffAccessCheckProvider.overrideWithValue(() async => true),
    ]);

    expect(find.text('Hello, Jean'), findsOneWidget);
    Finder tile(String label, String value) => find.descendant(
      of: find.widgetWithText(StatTile, label),
      matching: find.text(value),
    );
    expect(tile('New today', '2'), findsOneWidget);
    expect(tile('In progress', '1'), findsOneWidget);
    expect(tile('Under review', '0'), findsOneWidget);
    expect(tile('Resolved this week', '1'), findsOneWidget);

    // New: most urgent and most backed first.
    expect(find.text('Power out in the library'), findsOneWidget);
    expect(find.text('Streetlight out on the main path'), findsOneWidget);
    expect(find.text('Leaking tap in Block C'), findsNothing);

    await tester.tap(find.text('Mine'));
    await tester.pumpAndSettle();
    expect(find.text('Leaking tap in Block C'), findsOneWidget);
    expect(find.text('Broken chair in Room 204'), findsNothing);
  });
}
