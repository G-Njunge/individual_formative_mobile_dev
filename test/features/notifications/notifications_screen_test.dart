import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:individual_formative/core/firebase/firebase_providers.dart';
import 'package:individual_formative/core/storage/shared_preferences_provider.dart';
import 'package:individual_formative/core/theme/app_theme.dart';
import 'package:individual_formative/features/notifications/presentation/notifications_screen.dart';
import 'package:individual_formative/features/reports/application/report_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore db;
  late SharedPreferences prefs;

  Map<String, dynamic> reportDoc(int ticket, String status, String? by) => {
    'ticketNumber': ticket,
    'title': 'Report $ticket',
    'description': '',
    'category': 'water',
    'location': 'Block C',
    'urgency': 'medium',
    'status': status,
    'reporterId': by,
    'reporterName': by == null ? null : 'Amani Mugisha',
    'anonymous': by == null,
    'photoCount': 0,
    'assignedTo': null,
    'meTooCount': 0,
    'createdAt': Timestamp.fromDate(DateTime.now()),
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = FakeFirebaseFirestore();
    final now = Timestamp.now();

    // My named report, just resolved; a report I back; and my anonymous
    // report with a staff update (no stored notification for that one).
    await db.doc('reports/mine').set(reportDoc(1038, 'resolved', 'u1'));
    await db.doc('reports/backed').set(reportDoc(1050, 'in_progress', 'u9'));
    await db.doc('reports/anon').set(reportDoc(1060, 'in_progress', null));
    await db.doc('users/u1/reports/anon').set({'createdAt': now});
    await db.collection('reports/anon/updates').add({
      'status': 'in_progress',
      'previousStatus': 'submitted',
      'note': null,
      'byUid': 's1',
      'byName': 'Jean Habimana',
      'createdAt': now,
    });
    for (final (id, report, ticket, status) in [
      ('n1', 'mine', 1038, 'resolved'),
      ('n2', 'backed', 1050, 'in_progress'),
    ]) {
      await db.doc('users/u1/notifications/$id').set({
        'type': 'status',
        'reportId': report,
        'ticketNumber': ticket,
        'reportTitle': 'Report $ticket',
        'status': status,
        'note': null,
        'read': false,
        'createdAt': now,
      });
    }
    await db.collection('announcements').add({
      'title': 'Planned water cut in Hostel A on Saturday',
      'body': '9:00 to 12:00',
      'byName': 'Jean',
      'createdAt': now,
    });
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const NotificationsScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('u1'),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the announcement and every kind of notification', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('CAMPUS ANNOUNCEMENT'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(
      find.textContaining('#1038 was marked Resolved. Is it fixed?'),
      findsOneWidget,
    );
    expect(find.textContaining('#1050 is now In progress'), findsOneWidget);
    // Built on the phone from the anonymous report's timeline.
    expect(find.textContaining('#1060 is now In progress'), findsOneWidget);
  });

  testWidgets('"Yes, fixed" answers the question in place', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Yes, fixed'));
    await tester.pumpAndSettle();
    expect((await db.doc('reports/mine').get()).data()!['confirmed'], isTrue);
    expect(find.textContaining('Is it fixed?'), findsNothing);
    expect(find.text('Yes, fixed'), findsNothing);
  });

  testWidgets('Mark all read clears stored and phone-built notifications', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    final stored = await db.collection('users/u1/notifications').get();
    expect(stored.docs.every((d) => d.data()['read'] == true), isTrue);
    final link = await db.doc('users/u1/reports/anon').get();
    expect(link.data()!['seenAt'], isNotNull);
  });
}
