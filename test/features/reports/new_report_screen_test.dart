import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:individual_formative/core/firebase/firebase_providers.dart';
import 'package:individual_formative/core/router/routes.dart';
import 'package:individual_formative/core/theme/app_theme.dart';
import 'package:individual_formative/core/widgets/neu_switch.dart';
import 'package:individual_formative/features/auth/application/auth_providers.dart';
import 'package:individual_formative/features/auth/data/app_user.dart';
import 'package:individual_formative/features/reports/application/report_providers.dart';
import 'package:individual_formative/features/reports/data/photo_picker.dart';
import 'package:individual_formative/features/reports/presentation/new_report_screen.dart';

class FakePhotoPicker extends PhotoPicker {
  int picks = 0;

  @override
  Future<Uint8List?> pick() async {
    picks++;
    return Uint8List.fromList(_tinyPng);
  }
}

void main() {
  late FakeFirebaseFirestore db;
  late FakePhotoPicker picker;

  setUp(() {
    db = FakeFirebaseFirestore();
    picker = FakePhotoPicker();
  });

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const NewReportScreen()),
        GoRoute(
          path: Routes.reportSubmittedPattern,
          builder: (_, state) =>
              Text('Submitted ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          photoPickerProvider.overrideWithValue(picker),
          sessionProvider.overrideWithValue(
            const Session(
              SessionStatus.student,
              profile: AppUser(
                uid: 'u1',
                name: 'Amani Mugisha',
                email: 'a.mugisha@alustudent.com',
                role: UserRole.student,
              ),
            ),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Drags the form (its ListView, not the text fields' own scrollables)
  /// until [finder] is on screen.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await scrollTo(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('submitting an empty form shows every problem at once', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a category'), findsOneWidget);
    for (final error in [
      'Title is required',
      'Description is required',
      'Location is required',
    ]) {
      await scrollTo(tester, find.text(error));
      expect(find.text(error), findsOneWidget);
    }
    expect((await db.collection('reports').get()).docs, isEmpty);
  });

  testWidgets('urgency hint follows the chosen level', (tester) async {
    await pumpForm(tester);
    await tapVisible(tester, find.text('High'));
    expect(
      find.text('High: it is unsafe or blocks a whole building.'),
      findsOneWidget,
    );
  });

  testWidgets('a complete report with a photo is saved and confirmed', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    expect(picker.picks, 1);
    expect(find.bySemanticsLabel('Remove photo 1'), findsOneWidget);

    await tapVisible(tester, find.text('Water'));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Leaking tap in Block C');
    await tester.enterText(fields.at(1), 'The tap is spraying water.');
    await tester.enterText(fields.at(2), 'Block C, ground floor');
    await tapVisible(tester, find.byType(NeuSwitch));

    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    final docs = (await db.collection('reports').get()).docs;
    expect(docs, hasLength(1));
    final data = docs.single.data();
    expect(data['category'], 'water');
    expect(data['location'], 'Block C, ground floor');
    expect(data['anonymous'], isTrue);
    expect(data['reporterName'], isNull);
    expect(data['photoCount'], 1);
    expect(find.text('Submitted ${docs.single.id}'), findsOneWidget);
  });
}

/// A 1×1 transparent PNG, so Image.memory has something real to decode.
const _tinyPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
