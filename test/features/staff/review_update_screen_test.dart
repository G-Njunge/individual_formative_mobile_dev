import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:individual_formative/core/firebase/firebase_providers.dart';
import 'package:individual_formative/core/theme/app_theme.dart';
import 'package:individual_formative/features/auth/application/auth_providers.dart';
import 'package:individual_formative/features/auth/data/app_user.dart';
import 'package:individual_formative/features/reports/application/report_providers.dart';
import 'package:individual_formative/features/reports/data/photo_picker.dart';
import 'package:individual_formative/features/staff/application/staff_providers.dart';
import 'package:individual_formative/features/staff/presentation/review_update_screen.dart';

class FakePhotoPicker extends PhotoPicker {
  @override
  Future<Uint8List?> pick() async => Uint8List.fromList(_tinyPng);
}

const jean = AppUser(
  uid: 's1',
  name: 'Jean Habimana',
  email: 'jean.h@alueducation.com',
  role: UserRole.staff,
  team: 'Plumbing',
  approved: true,
);

void main() {
  late FakeFirebaseFirestore db;
  late bool hasAccess;

  setUp(() async {
    db = FakeFirebaseFirestore();
    hasAccess = true;
    await db.doc('users/s1').set({
      'name': 'Jean Habimana',
      'role': 'staff',
      'approved': true,
      'team': 'Plumbing',
    });
    for (final (id, ticket) in [('r1', 1042), ('r0', 1040)]) {
      await db.doc('reports/$id').set({
        'ticketNumber': ticket,
        'title': 'Leaking tap in the Block C washroom',
        'description': 'The tap by the second sink is spraying water.',
        'category': 'water',
        'location': 'Block C',
        'urgency': 'medium',
        'status': 'submitted',
        'reporterId': 'u1',
        'reporterName': 'Amani Mugisha',
        'anonymous': false,
        'photoCount': 0,
        'assignedTo': null,
        'meTooCount': 12,
      });
    }
  });

  Future<void> pumpReview(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Queue')),
          routes: [
            GoRoute(
              path: 'review',
              builder: (_, _) => const ReviewUpdateScreen(reportId: 'r1'),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          photoPickerProvider.overrideWithValue(FakePhotoPicker()),
          staffAccessCheckProvider.overrideWithValue(() async => hasAccess),
          sessionProvider.overrideWithValue(
            const Session(SessionStatus.staff, profile: jean),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    router.push('/review');
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the ticket summary', (tester) async {
    await pumpReview(tester);
    expect(find.text('TICKET #1042'), findsOneWidget);
    expect(find.text('WATER · MEDIUM'), findsOneWidget);
    expect(find.text('Block C · 12 me too'), findsOneWidget);
    expect(find.textContaining('Reported by Amani M.'), findsOneWidget);
    expect(find.text('REOPENED BY THE REPORTER'), findsNothing);
  });

  testWidgets('shows why the reporter reopened it', (tester) async {
    await db.collection('reports/r1/updates').add({
      'status': 'submitted',
      'previousStatus': 'resolved',
      'note': 'Reopened: Still dripping at night',
      'byUid': '',
      'byName': 'Reporter',
      'createdAt': DateTime(2026, 11, 6),
    });
    await pumpReview(tester);
    expect(find.text('REOPENED BY THE REPORTER'), findsOneWidget);
    expect(find.text('Reopened: Still dripping at night'), findsOneWidget);
  });

  testWidgets('saves a status, assignee and note, then goes back', (
    tester,
  ) async {
    await pumpReview(tester);

    await tester.tap(find.text('In progress'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jean Habimana (you)'));
    await tester.pumpAndSettle();
    expect(find.text('Jean Habimana, Plumbing'), findsOneWidget);

    await scrollTo(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Plumber on the way.');
    await tester.tap(find.text('Save update'));
    await tester.pumpAndSettle();

    expect(find.text('Queue'), findsOneWidget);
    final saved = (await db.doc('reports/r1').get()).data()!;
    expect(saved['status'], 'in_progress');
    expect((saved['assignedTo'] as Map)['uid'], 's1');
    final note = (await db.collection('users/u1/notifications').get()).docs;
    expect(note.single.data()['note'], 'Plumber on the way.');
  });

  testWidgets('Resolved reveals the after photo', (tester) async {
    await pumpReview(tester);
    expect(find.text('After photo'), findsNothing);

    await tester.tap(find.text('Resolved'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Add a photo of the fix'));
    await tester.tap(find.text('Add a photo of the fix'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Photo of the fix'), findsOneWidget);

    await tester.tap(find.text('Save update'));
    await tester.pumpAndSettle();
    expect((await db.doc('reports/r1').get()).data()!['hasAfterPhoto'], isTrue);
  });

  testWidgets('Duplicate closes the report against the original', (
    tester,
  ) async {
    await pumpReview(tester);
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '1040');
    await tester.tap(find.text('Close as duplicate'));
    await tester.pumpAndSettle();

    expect(find.text('Queue'), findsOneWidget);
    final saved = (await db.doc('reports/r1').get()).data()!;
    expect(saved['status'], 'resolved');
    expect((saved['duplicateOf'] as Map)['ticketNumber'], 1040);
  });

  testWidgets('explains when staff access is not switched on', (tester) async {
    hasAccess = false;
    await pumpReview(tester);
    await tester.tap(find.text('Under review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save update'));
    await tester.pumpAndSettle();

    final message = find.textContaining("staff access isn't switched on");
    await scrollTo(tester, message);
    expect(message, findsOneWidget);
    expect((await db.doc('reports/r1').get()).data()!['status'], 'submitted');
  });
}

const _tinyPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
