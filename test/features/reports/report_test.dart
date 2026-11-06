import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/models/report_enums.dart';
import 'package:individual_formative/features/reports/data/report.dart';

void main() {
  group('Report', () {
    test('reads every field from Firestore', () {
      final created = DateTime(2026, 11, 6, 7, 42);
      final r = Report.fromJson('r1', {
        'ticketNumber': 1042,
        'title': 'Leaking tap in the Block C washroom',
        'description': 'Spraying water.',
        'category': 'water',
        'location': 'Block C',
        'urgency': 'high',
        'status': 'in_progress',
        'reporterId': 'u1',
        'reporterName': 'Amani Mugisha',
        'anonymous': false,
        'photoCount': 2,
        'assignedTo': {
          'uid': 's1',
          'name': 'Jean Habimana',
          'team': 'Plumbing',
        },
        'meTooCount': 12,
        'createdAt': Timestamp.fromDate(created),
      });

      expect(r.ticketLabel, 'TICKET #1042');
      expect(r.category, ReportCategory.water);
      expect(r.urgency, Urgency.high);
      expect(r.status, ReportStatus.inProgress);
      expect(r.photoCount, 2);
      expect(r.assignedTo!.team, 'Plumbing');
      expect(r.meTooCount, 12);
      expect(r.createdAt, created);
      expect(r.isReportedBy('u1'), isTrue);
    });

    test('falls back to safe defaults for missing or unknown values', () {
      final r = Report.fromJson('r1', {'status': 'nonsense'});
      expect(r.status, ReportStatus.submitted);
      expect(r.category, ReportCategory.other);
      expect(r.urgency, Urgency.medium);
      expect(r.createdAt, isNull);
      expect(r.assignedTo, isNull);
    });

    test('never writes the name or id of an anonymous reporter', () {
      const r = Report(
        id: 'r1',
        ticketNumber: 1001,
        title: 'Broken chair',
        description: 'Leg snapped.',
        category: ReportCategory.furniture,
        location: 'Room 204',
        urgency: Urgency.low,
        status: ReportStatus.submitted,
        reporterId: 'u1',
        reporterName: 'Amani Mugisha',
        anonymous: true,
      );
      final json = r.toJson();
      expect(json['reporterName'], isNull);
      expect(json['reporterId'], isNull);
      expect(json['category'], 'furniture');
      expect(json['status'], 'submitted');
    });

    test('reads what staff add, and a new report never carries it', () {
      final r = Report.fromJson('r1', {
        'hasAfterPhoto': true,
        'duplicateOf': {'id': 'r0', 'ticketNumber': 1040},
      });
      expect(r.hasAfterPhoto, isTrue);
      expect(r.duplicateOf?.ticketNumber, 1040);

      final fresh = Report.fromJson('r2', {}).toJson();
      expect(fresh.containsKey('hasAfterPhoto'), isFalse);
      expect(fresh.containsKey('duplicateOf'), isFalse);
    });
  });

  test('ReportUpdate knows a status change from a note', () {
    final moved = ReportUpdate.fromJson('a', {
      'status': 'in_progress',
      'previousStatus': 'submitted',
    });
    final noteOnly = ReportUpdate.fromJson('b', {
      'status': 'in_progress',
      'previousStatus': 'in_progress',
      'note': 'Parts ordered',
    });
    expect(moved.changedStatus, isTrue);
    expect(noteOnly.changedStatus, isFalse);
    expect(moved.toJson()['previousStatus'], 'submitted');
  });

  test('ReportUpdate treats a blank note as no note', () {
    final u = ReportUpdate.fromJson('x', {
      'status': 'under_review',
      'note': '   ',
      'byName': 'Jean Habimana',
    });
    expect(u.status, ReportStatus.underReview);
    expect(u.note, isNull);
  });
}
