import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/config/app_config.dart';
import 'package:individual_formative/core/errors/user_facing_exception.dart';
import 'package:individual_formative/core/models/report_enums.dart';
import 'package:individual_formative/features/auth/data/app_user.dart';
import 'package:individual_formative/features/reports/data/report.dart';
import 'package:individual_formative/features/reports/data/report_repository.dart';

const amani = AppUser(
  uid: 'u1',
  name: 'Amani Mugisha',
  email: 'a.mugisha@alustudent.com',
  role: UserRole.student,
);

ReportDraft draft({bool anonymous = false, String title = 'Leaking tap'}) =>
    ReportDraft(
      title: '  $title ',
      description: 'Spraying water from the pipe.',
      category: ReportCategory.water,
      location: 'Block C',
      urgency: Urgency.high,
      anonymous: anonymous,
    );

void main() {
  late FakeFirebaseFirestore db;
  late ReportRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = ReportRepository(db);
  });

  group('createReport', () {
    test('writes a submitted report with the next ticket number', () async {
      final first = await repo.createReport(draft: draft(), reporter: amani);
      final second = await repo.createReport(draft: draft(), reporter: amani);

      final a = (await db.doc('reports/$first').get()).data()!;
      final b = (await db.doc('reports/$second').get()).data()!;
      expect(a['ticketNumber'], ReportRepository.firstTicketNumber);
      expect(b['ticketNumber'], ReportRepository.firstTicketNumber + 1);
      expect((await db.doc('counters/reports').get()).data(), {'last': 1002});

      expect(a['title'], 'Leaking tap', reason: 'trimmed');
      expect(a['status'], 'submitted');
      expect(a['reporterId'], 'u1');
      expect(a['reporterName'], 'Amani Mugisha');
      expect(a['meTooCount'], 0);
      expect(a['assignedTo'], isNull);
      expect(a['createdAt'], isA<Timestamp>());
    });

    test(
      'anonymous reports store no name or id, only a private link',
      () async {
        final id = await repo.createReport(
          draft: draft(anonymous: true),
          reporter: amani,
        );
        final data = (await db.doc('reports/$id').get()).data()!;
        expect(data['anonymous'], isTrue);
        expect(data['reporterName'], isNull);
        expect(data['reporterId'], isNull);
        expect(data.values, isNot(contains('u1')));

        final link = await db.doc('users/u1/reports/$id').get();
        expect(link.exists, isTrue);
        expect(link.data()!.keys, ['createdAt']);
      },
    );

    test('named reports get no private link', () async {
      await repo.createReport(draft: draft(), reporter: amani);
      expect((await db.collection('users/u1/reports').get()).docs, isEmpty);
    });

    test('stores each photo in its own document, in order', () async {
      final photos = [
        Uint8List.fromList([1, 2, 3]),
        Uint8List.fromList([4, 5]),
      ];
      final id = await repo.createReport(
        draft: draft(),
        reporter: amani,
        photos: photos,
      );

      final data = (await db.doc('reports/$id').get()).data()!;
      expect(data['photoCount'], 2);
      expect(await repo.fetchPhotos(id), photos);
    });

    test('refuses more than the allowed number of photos', () async {
      final photos = List.generate(
        AppConfig.maxPhotos + 1,
        (_) => Uint8List.fromList([1]),
      );
      await expectLater(
        repo.createReport(draft: draft(), reporter: amani, photos: photos),
        throwsA(isA<UserFacingException>()),
      );
      expect((await db.collection('reports').get()).docs, isEmpty);
    });

    test('refuses a photo that is too large', () async {
      final huge = Uint8List(AppConfig.photoMaxBytes + 1);
      await expectLater(
        repo.createReport(draft: draft(), reporter: amani, photos: [huge]),
        throwsA(isA<UserFacingException>()),
      );
    });
  });

  group('reading', () {
    test('watchNamedBy only returns the named reports of the student\'s own reports', () async {
      await repo.createReport(
        draft: draft(title: 'Mine one'),
        reporter: amani,
      );
      await repo.createReport(
        draft: draft(title: 'Someone else'),
        reporter: const AppUser(
          uid: 'u2',
          name: 'Other Student',
          email: 'o@alustudent.com',
          role: UserRole.student,
        ),
      );

      await repo.createReport(
        draft: draft(title: 'Mine, anonymous', anonymous: true),
        reporter: amani,
      );

      final mine = await repo.watchNamedBy('u1').first;
      expect([for (final r in mine) r.title], ['Mine one']);
      final all = await repo.watchAll().first;
      expect(all, hasLength(3));
    });

    test('anonymous reports are found through the private links', () async {
      final id = await repo.createReport(
        draft: draft(title: 'Secret one', anonymous: true),
        reporter: amani,
      );
      final ids = await repo.watchAnonymousIds('u1').first;
      expect(ids, {id});
      expect(await repo.watchAnonymousIds('u2').first, isEmpty);

      final reports = await repo.watchByIds(ids).first;
      expect([for (final r in reports) r.title], ['Secret one']);
    });

    test('watchByIds splits more than 30 ids into several queries', () async {
      final ids = <String>[];
      for (var i = 0; i < 32; i++) {
        ids.add(
          await repo.createReport(
            draft: draft(title: 'Report number $i', anonymous: true),
            reporter: amani,
          ),
        );
      }
      expect(await repo.watchByIds(ids).first, hasLength(32));
      expect(await repo.watchByIds(const []).first, isEmpty);
    });

    test('watchReport emits null for a missing report', () async {
      expect(await repo.watchReport('nope').first, isNull);
    });

    test('watchUpdates lists the timeline oldest first', () async {
      final id = await repo.createReport(draft: draft(), reporter: amani);
      final updates = db.collection('reports/$id/updates');
      await updates.add({
        'status': 'in_progress',
        'byName': 'Jean',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 6, 9)),
      });
      await updates.add({
        'status': 'under_review',
        'byName': 'Jean',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 6, 8)),
      });

      final list = await repo.watchUpdates(id).first;
      expect(
        [for (final u in list) u.status],
        [ReportStatus.underReview, ReportStatus.inProgress],
      );
    });
  });
}
