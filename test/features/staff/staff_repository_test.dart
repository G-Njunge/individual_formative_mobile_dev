import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/errors/user_facing_exception.dart';
import 'package:individual_formative/core/models/report_enums.dart';
import 'package:individual_formative/features/auth/data/app_user.dart';
import 'package:individual_formative/features/reports/data/report.dart';
import 'package:individual_formative/features/staff/data/staff_repository.dart';
import 'package:individual_formative/features/staff/data/staff_update.dart';

const jean = AppUser(
  uid: 's1',
  name: 'Jean Habimana',
  email: 'jean.h@alueducation.com',
  role: UserRole.staff,
  team: 'Plumbing',
  approved: true,
);

const jeanAssignee = Assignee(
  uid: 's1',
  name: 'Jean Habimana',
  team: 'Plumbing',
);

void main() {
  late FakeFirebaseFirestore db;
  late StaffRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = StaffRepository(db);
  });

  /// Adds a report and returns it as the app would read it.
  Future<Report> addReport({
    String id = 'r1',
    int ticket = 1042,
    bool anonymous = false,
    List<String> supporters = const [],
  }) async {
    await db.doc('reports/$id').set({
      'ticketNumber': ticket,
      'title': 'Leaking tap in Block C',
      'description': 'Spraying water.',
      'category': 'water',
      'location': 'Block C',
      'urgency': 'medium',
      'status': 'submitted',
      'reporterId': anonymous ? null : 'u1',
      'reporterName': anonymous ? null : 'Amani Mugisha',
      'anonymous': anonymous,
      'photoCount': 0,
      'assignedTo': null,
      'meTooCount': supporters.length,
    });
    for (final uid in supporters) {
      await db.doc('reports/$id/supporters/$uid').set({'createdAt': 1});
    }
    final snap = await db.doc('reports/$id').get();
    return Report.fromJson(id, snap.data()!);
  }

  Future<List<Map<String, dynamic>>> notificationsFor(String uid) async => [
    for (final d
        in (await db.collection('users/$uid/notifications').get()).docs)
      d.data(),
  ];

  group('saveUpdate', () {
    test('changes the report and adds a timeline entry', () async {
      final report = await addReport();
      await repo.saveUpdate(
        report: report,
        by: jean,
        draft: const StaffUpdateDraft(
          status: ReportStatus.inProgress,
          assignee: jeanAssignee,
          note: '  Plumber on the way. ',
        ),
      );

      final saved = (await db.doc('reports/r1').get()).data()!;
      expect(saved['status'], 'in_progress');
      expect(saved['assignedTo'], {
        'uid': 's1',
        'name': 'Jean Habimana',
        'team': 'Plumbing',
      });
      expect(saved['title'], 'Leaking tap in Block C');

      final updates = (await db.collection('reports/r1/updates').get()).docs;
      expect(updates, hasLength(1));
      final u = ReportUpdate.fromJson(updates.single.id, updates.single.data());
      expect(u.status, ReportStatus.inProgress);
      expect(u.previousStatus, ReportStatus.submitted);
      expect(u.changedStatus, isTrue);
      expect(u.note, 'Plumber on the way.');
      expect(u.byName, 'Jean Habimana');
      expect(u.byTeam, 'Plumbing');
    });

    test('notifies the named reporter and every supporter', () async {
      final report = await addReport(supporters: ['u2', 'u3']);
      await repo.saveUpdate(
        report: report,
        by: jean,
        draft: const StaffUpdateDraft(status: ReportStatus.underReview),
      );

      for (final uid in ['u1', 'u2', 'u3']) {
        final n = await notificationsFor(uid);
        expect(n, hasLength(1), reason: uid);
        expect(n.single['type'], 'status');
        expect(n.single['status'], 'under_review');
        expect(n.single['ticketNumber'], 1042);
        expect(n.single['read'], isFalse);
      }
    });

    test('a note without a status change is a "note" notification', () async {
      final report = await addReport();
      await repo.saveUpdate(
        report: report,
        by: jean,
        draft: const StaffUpdateDraft(
          status: ReportStatus.submitted,
          note: 'Looking into it',
        ),
      );
      final n = await notificationsFor('u1');
      expect(n.single['type'], 'note');
      expect(n.single['note'], 'Looking into it');
    });

    test('stores nothing that points to an anonymous reporter', () async {
      final report = await addReport(anonymous: true, supporters: ['u2']);
      await repo.saveUpdate(
        report: report,
        by: jean,
        draft: const StaffUpdateDraft(status: ReportStatus.inProgress),
      );
      expect(await notificationsFor('u1'), isEmpty);
      expect(await notificationsFor('u2'), hasLength(1));
    });

    test('never notifies the staff member making the change', () async {
      final report = await addReport(supporters: ['s1']);
      await repo.saveUpdate(
        report: report,
        by: jean,
        draft: const StaffUpdateDraft(status: ReportStatus.inProgress),
      );
      expect(await notificationsFor('s1'), isEmpty);
    });

    test('splits a very large fan-out over several batches', () async {
      final supporters = [for (var i = 0; i < 600; i++) 'p$i'];
      final report = await addReport(supporters: supporters);
      await repo.saveUpdate(
        report: report,
        by: jean,
        draft: const StaffUpdateDraft(status: ReportStatus.resolved),
      );
      for (final uid in ['u1', 'p0', 'p599']) {
        expect(await notificationsFor(uid), hasLength(1), reason: uid);
      }
    });

    test('stores the after photo when resolving', () async {
      final report = await addReport();
      final photo = Uint8List.fromList([1, 2, 3]);
      await repo.saveUpdate(
        report: report,
        by: jean,
        draft: StaffUpdateDraft(
          status: ReportStatus.resolved,
          afterPhoto: photo,
        ),
      );
      final saved = (await db.doc('reports/r1').get()).data()!;
      expect(saved['hasAfterPhoto'], isTrue);
      final after = (await db.doc('reports/r1/photos/after').get()).data()!;
      expect((after['data'] as Blob).bytes, photo);
    });

    test('refuses an after photo unless resolved', () async {
      final report = await addReport();
      expect(
        () => repo.saveUpdate(
          report: report,
          by: jean,
          draft: StaffUpdateDraft(
            status: ReportStatus.inProgress,
            afterPhoto: Uint8List.fromList([1]),
          ),
        ),
        throwsA(isA<UserFacingException>()),
      );
    });

    test('refuses a save that changes nothing', () async {
      final report = await addReport();
      expect(
        () => repo.saveUpdate(
          report: report,
          by: jean,
          draft: const StaffUpdateDraft(
            status: ReportStatus.submitted,
            note: '   ',
          ),
        ),
        throwsA(
          isA<UserFacingException>().having(
            (e) => e.message,
            'message',
            contains('Nothing to save'),
          ),
        ),
      );
      expect((await db.collection('reports/r1/updates').get()).docs, isEmpty);
    });
  });

  group('markDuplicate', () {
    test('resolves the report and links it to the original', () async {
      await addReport(id: 'r0', ticket: 1040);
      final report = await addReport(supporters: ['u2']);

      final original = await repo.markDuplicate(
        report: report,
        originalTicket: 1040,
        by: jean,
      );
      expect(original.id, 'r0');

      final saved = Report.fromJson(
        'r1',
        (await db.doc('reports/r1').get()).data()!,
      );
      expect(saved.status, ReportStatus.resolved);
      expect(saved.duplicateOf?.ticketNumber, 1040);
      expect(saved.duplicateOf?.id, 'r0');
      final n = await notificationsFor('u2');
      expect(n.single['note'], startsWith('Duplicate of #1040'));
    });

    test('explains an unknown ticket or the same ticket', () async {
      final report = await addReport();
      expect(
        () =>
            repo.markDuplicate(report: report, originalTicket: 9999, by: jean),
        throwsA(
          isA<UserFacingException>().having(
            (e) => e.message,
            'message',
            'There is no ticket #9999.',
          ),
        ),
      );
      expect(
        () =>
            repo.markDuplicate(report: report, originalTicket: 1042, by: jean),
        throwsA(isA<UserFacingException>()),
      );
    });
  });

  test('watchStaffMembers lists approved staff only, by name', () async {
    Future<void> user(String id, Map<String, dynamic> data) =>
        db.doc('users/$id').set(data);
    await user('s1', {
      'name': 'Jean Habimana',
      'role': 'staff',
      'approved': true,
    });
    await user('s2', {'name': 'Aline K', 'role': 'staff', 'approved': true});
    await user('s3', {
      'name': 'New Person',
      'role': 'staff',
      'approved': false,
    });
    await user('u1', {'name': 'Amani', 'role': 'student'});

    final staff = await repo.watchStaffMembers().first;
    expect([for (final s in staff) s.name], ['Aline K', 'Jean Habimana']);
  });
}
