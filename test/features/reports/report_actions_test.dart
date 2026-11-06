import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/errors/user_facing_exception.dart';
import 'package:individual_formative/core/models/report_enums.dart';
import 'package:individual_formative/features/reports/data/report.dart';
import 'package:individual_formative/features/reports/data/report_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ReportRepository repo;

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = ReportRepository(db);
    await db.doc('reports/r1').set({
      'ticketNumber': 1042,
      'title': 'Leaking tap',
      'status': 'submitted',
      'reporterId': 'u1',
      'anonymous': false,
      'meTooCount': 3,
    });
  });

  Future<Map<String, dynamic>> report() async =>
      (await db.doc('reports/r1').get()).data()!;

  group('Me too', () {
    test(
      'adds the supporter, the following record and one to the count',
      () async {
        await repo.setSupport(reportId: 'r1', uid: 'u2', support: true);
        expect((await report())['meTooCount'], 4);
        expect((await db.doc('reports/r1/supporters/u2').get()).exists, isTrue);
        expect((await db.doc('users/u2/following/r1').get()).exists, isTrue);
        expect(await repo.watchIsSupporter('r1', 'u2').first, isTrue);
        expect(await repo.watchFollowingIds('u2').first, {'r1'});
      },
    );

    test(
      'taking support back removes both records and one from the count',
      () async {
        await repo.setSupport(reportId: 'r1', uid: 'u2', support: true);
        await repo.setSupport(reportId: 'r1', uid: 'u2', support: false);
        expect((await report())['meTooCount'], 3);
        expect(
          (await db.doc('reports/r1/supporters/u2').get()).exists,
          isFalse,
        );
        expect(await repo.watchFollowingIds('u2').first, isEmpty);
      },
    );
  });

  group('confirm or reopen', () {
    setUp(() => db.doc('reports/r1').update({'status': 'resolved'}));

    test('"Yes, fixed" marks the report confirmed', () async {
      await repo.confirmFixed('r1');
      final r = Report.fromJson('r1', await report());
      expect(r.confirmed, isTrue);
      expect(r.awaitsConfirmation, isFalse);
    });

    test(
      'reopen goes back to submitted with the reason on the timeline',
      () async {
        await repo.reopen('r1', reason: '  Still dripping at night ');
        expect((await report())['status'], 'submitted');

        final updates = await repo.watchUpdates('r1').first;
        expect(updates, hasLength(1));
        final u = updates.single;
        expect(u.status, ReportStatus.submitted);
        expect(u.previousStatus, ReportStatus.resolved);
        expect(u.note, 'Reopened: Still dripping at night');
        // No user id, so an anonymous reporter isn't revealed.
        expect(u.byUid, '');
        expect(u.byName, ReportRepository.reopenedBy);
      },
    );

    test('reopen needs a reason', () async {
      expect(
        () => repo.reopen('r1', reason: '  ok '),
        throwsA(isA<UserFacingException>()),
      );
      expect((await report())['status'], 'resolved');
    });
  });

  test('anonymous read state is stored on the private link', () async {
    await db.doc('users/u1/reports/r9').set({'createdAt': DateTime(2026)});
    expect(await repo.watchAnonymousSeen('u1').first, {'r9': null});

    await repo.markAnonymousSeen('u1', ['r9']);
    final seen = await repo.watchAnonymousSeen('u1').first;
    expect(seen['r9'], isNotNull);
    expect(await repo.watchAnonymousIds('u1').first, {'r9'});
  });
}
