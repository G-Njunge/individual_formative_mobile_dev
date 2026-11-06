import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/models/report_enums.dart';
import 'package:individual_formative/core/utils/validators.dart';
import 'package:individual_formative/core/widgets/app_icons.dart';
import 'package:individual_formative/core/widgets/async_states.dart';
import 'package:individual_formative/core/widgets/buttons.dart';
import 'package:individual_formative/core/widgets/filter_chip_row.dart';
import 'package:individual_formative/core/widgets/floating_nav_bar.dart';
import 'package:individual_formative/core/widgets/neu_switch.dart';
import 'package:individual_formative/core/widgets/neu_text_field.dart';
import 'package:individual_formative/core/widgets/password_strength_meter.dart';
import 'package:individual_formative/core/widgets/pills.dart';
import 'package:individual_formative/core/widgets/report_card.dart';
import 'package:individual_formative/core/widgets/segmented_toggle.dart';
import 'package:individual_formative/core/widgets/selectable_tile.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        PrimaryButton(label: 'Submit report', onPressed: () => taps++),
      );
      await tester.tap(find.text('Submit report'));
      expect(taps, 1);
    });

    testWidgets('shows a spinner and ignores taps while loading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpApp(
        PrimaryButton(label: 'Save', loading: true, onPressed: () => taps++),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 0);
    });

    testWidgets('is announced as a disabled button when onPressed is null', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const PrimaryButton(label: 'Sign in', onPressed: null),
      );
      expect(
        tester.getSemantics(find.byType(PrimaryButton)),
        matchesSemantics(
          label: 'Sign in',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('NeuTextField', () {
    testWidgets('shows the validator error under the field', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpApp(
        Form(
          key: formKey,
          child: const NeuTextField(
            label: 'Confirm password',
            initialValue: 'abc',
            validator: _alwaysMismatch,
          ),
        ),
      );
      expect(find.text('Passwords do not match'), findsNothing);
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('counts characters and stops at maxLength', (tester) async {
      final controller = TextEditingController();
      await tester.pumpApp(
        NeuTextField(
          label: 'Description',
          controller: controller,
          maxLines: 4,
          maxLength: 10,
          showCounter: true,
        ),
      );
      expect(find.text('0 / 10'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'A leaking tap here');
      await tester.pump();
      expect(controller.text, 'A leaking ');
      expect(find.text('10 / 10'), findsOneWidget);
    });

    testWidgets('Show reveals an obscured password', (tester) async {
      await tester.pumpApp(
        const NeuTextField(
          label: 'Password',
          initialValue: 'secret123',
          obscure: true,
          canRevealObscured: true,
        ),
      );
      TextField field() => tester.widget<TextField>(find.byType(TextField));
      expect(field().obscureText, isTrue);
      await tester.tap(find.text('Show'));
      await tester.pump();
      expect(field().obscureText, isFalse);
      expect(find.text('Hide'), findsOneWidget);
    });
  });

  testWidgets('SegmentedToggle reports the tapped option', (tester) async {
    String? picked;
    await tester.pumpApp(
      SegmentedToggle<String>(
        options: const [
          SegmentOption('student', 'Student'),
          SegmentOption('staff', 'Campus staff'),
        ],
        selected: 'student',
        onChanged: (v) => picked = v,
      ),
    );
    await tester.tap(find.text('Campus staff'));
    expect(picked, 'staff');
  });

  testWidgets('FilterChipRow reports the tapped chip', (tester) async {
    ReportStatus? picked;
    await tester.pumpApp(
      FilterChipRow<ReportStatus?>(
        options: const [
          ChipOption(null, 'All'),
          ChipOption(ReportStatus.submitted, 'Submitted'),
        ],
        selected: null,
        onSelected: (v) => picked = v,
      ),
    );
    await tester.tap(find.text('Submitted'));
    expect(picked, ReportStatus.submitted);
  });

  testWidgets('SelectableTile is announced as a checked radio', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(
      SelectableTile(
        label: 'Resolved',
        selected: true,
        isRadio: true,
        onTap: () {},
      ),
    );
    final data = tester
        .getSemantics(find.byType(SelectableTile))
        .getSemanticsData();
    expect(data.label, 'Resolved');
    expect(data.flagsCollection.isChecked, CheckedState.isTrue);
    expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    handle.dispose();
  });

  testWidgets('StatusPill writes the status as a word', (tester) async {
    await tester.pumpApp(const StatusPill(ReportStatus.inProgress));
    expect(find.text('In progress'), findsOneWidget);
    expect(find.bySemanticsLabel('Status: In progress'), findsOneWidget);
  });

  testWidgets('NeuSwitch flips its value', (tester) async {
    var value = false;
    await tester.pumpApp(
      StatefulBuilder(
        builder: (context, setState) => NeuSwitch(
          value: value,
          semanticLabel: 'Report anonymously',
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    await tester.tap(find.byType(NeuSwitch));
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

  testWidgets('FloatingNavBar labels icon-only buttons and reports taps', (
    tester,
  ) async {
    int? tapped;
    await tester.pumpApp(
      FloatingNavBar(
        currentIndex: 0,
        onTap: (i) => tapped = i,
        items: const [
          NavItem(icon: AppIcon.home, label: 'Home'),
          NavItem(icon: AppIcon.plus, label: 'New report', isAction: true),
          NavItem(icon: AppIcon.bell, label: 'Notifications', showBadge: true),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Notifications, unread'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('New report'));
    expect(tapped, 1);
  });

  testWidgets('ReportCard shows category, title, meta and me-too count', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpApp(
      ReportCard(
        category: ReportCategory.water,
        title: 'Leaking tap',
        place: 'Block C',
        timeLabel: '2h ago',
        status: ReportStatus.submitted,
        meTooCount: 12,
        onTap: () => opened = true,
      ),
    );
    expect(find.text('WATER'), findsOneWidget);
    expect(find.text('Leaking tap'), findsOneWidget);
    expect(find.text('Block C · 2h ago'), findsOneWidget);
    expect(find.text('12 me too'), findsOneWidget);
    await tester.tap(find.byType(ReportCard));
    expect(opened, isTrue);
  });

  testWidgets('PasswordStrengthMeter labels the strength', (tester) async {
    await tester.pumpApp(const PasswordStrengthMeter(password: 'campus2026'));
    expect(find.text('Medium'), findsOneWidget);
    expect(Validators.passwordStrength('campus2026').bars, 2);
  });

  testWidgets('PasswordChecklist marks what is done and what is not', (
    tester,
  ) async {
    await tester.pumpApp(const PasswordChecklist(password: 'campus2026'));
    expect(
      find.bySemanticsLabel('At least 8 characters: done'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('An uppercase letter (A-Z): not yet'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('A symbol, such as ! # or @: not yet'),
      findsOneWidget,
    );
  });

  group('AsyncValueView', () {
    Widget view(AsyncValue<List<int>> value) => AsyncValueView<List<int>>(
      value: value,
      isEmpty: (d) => d.isEmpty,
      empty: const EmptyState(title: 'Nothing here', message: 'Empty'),
      data: (d) => Text('${d.length} items'),
      onRetry: () {},
    );

    testWidgets('loading', (tester) async {
      await tester.pumpApp(view(const AsyncLoading()));
      expect(find.byType(LoadingState), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await tester.pumpApp(view(const AsyncData([])));
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('data', (tester) async {
      await tester.pumpApp(view(const AsyncData([1, 2])));
      expect(find.text('2 items'), findsOneWidget);
    });

    testWidgets('error offers a retry', (tester) async {
      await tester.pumpApp(
        view(AsyncError(Exception('unavailable'), StackTrace.empty)),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}

String? _alwaysMismatch(String? value) => 'Passwords do not match';
