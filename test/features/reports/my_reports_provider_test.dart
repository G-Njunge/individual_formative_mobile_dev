import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/firebase/firebase_providers.dart';
import 'package:individual_formative/core/models/report_enums.dart';
import 'package:individual_formative/features/auth/application/auth_providers.dart';
import 'package:individual_formative/features/auth/data/app_user.dart';
import 'package:individual_formative/features/reports/application/report_providers.dart';
import 'package:individual_formative/features/reports/data/report.dart';
import 'package:individual_formative/features/reports/data/report_repository.dart';

void main() {
  test('My reports joins named and anonymous reports, and knows both are '
      'mine', () async {
    final db = FakeFirebaseFirestore();
    final repo = ReportRepository(db);
    const amani = AppUser(
      uid: 'u1',
      name: 'Amani Mugisha',
      email: 'a.mugisha@alustudent.com',
      role: UserRole.student,
    );
    ReportDraft draft(String title, {bool anonymous = false}) => ReportDraft(
      title: title,
      description: 'd',
      category: ReportCategory.water,
      location: 'Block C',
      urgency: Urgency.low,
      anonymous: anonymous,
    );
    await repo.createReport(draft: draft('Named one'), reporter: amani);
    await repo.createReport(
      draft: draft('Anonymous one', anonymous: true),
      reporter: amani,
    );

    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        authUserProvider.overrideWith(
          (ref) => Stream.value(MockUser(uid: 'u1', isEmailVerified: true)),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(myReportsProvider, (_, _) {});
    addTearDown(sub.close);

    List<Report>? mine;
    for (var i = 0; i < 20 && mine == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      mine = container.read(myReportsProvider).value;
    }
    expect(
      mine!.map((r) => r.title),
      containsAll(['Named one', 'Anonymous one']),
    );

    final anonymous = mine.firstWhere((r) => r.anonymous);
    final isMine = container.listen(
      isMyReportProvider((id: anonymous.id, reporterId: anonymous.reporterId)),
      (_, _) {},
    );
    addTearDown(isMine.close);
    expect(isMine.read(), isTrue);
  });
}
