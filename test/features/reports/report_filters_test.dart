import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/models/report_enums.dart';
import 'package:individual_formative/features/reports/application/report_filters.dart';
import 'package:individual_formative/features/reports/data/report.dart';

Report report(
  String id, {
  String title = 'Something broken',
  String location = 'Block A',
  ReportStatus status = ReportStatus.submitted,
  int meToo = 0,
  DateTime? createdAt,
}) => Report(
  id: id,
  ticketNumber: 1000,
  title: title,
  description: 'd',
  category: ReportCategory.other,
  location: location,
  urgency: Urgency.medium,
  status: status,
  reporterId: 'u1',
  meTooCount: meToo,
  createdAt: createdAt,
);

void main() {
  final reports = [
    report(
      'tap',
      title: 'Leaking tap in the washroom',
      location: 'Block C',
      status: ReportStatus.inProgress,
      meToo: 12,
      createdAt: DateTime(2026, 11, 6, 9),
    ),
    report(
      'light',
      title: 'Streetlight out',
      location: 'Main path',
      meToo: 21,
      createdAt: DateTime(2026, 11, 6, 8),
    ),
    report(
      'chair',
      title: 'Broken chair',
      location: 'Block C, room 204',
      status: ReportStatus.resolved,
      createdAt: DateTime(2026, 11, 5),
    ),
  ];

  List<String> ids(List<Report> list) => [for (final r in list) r.id];

  group('filterReports', () {
    test('search matches title or place, ignoring case', () {
      expect(ids(filterReports(reports, query: 'TAP')), ['tap']);
      expect(ids(filterReports(reports, query: 'block c')), ['tap', 'chair']);
    });

    test('every word must match', () {
      expect(ids(filterReports(reports, query: 'block chair')), ['chair']);
      expect(filterReports(reports, query: 'block light'), isEmpty);
    });

    test('a blank search keeps everything', () {
      expect(filterReports(reports, query: '   '), hasLength(3));
    });

    test('filters by status', () {
      expect(ids(filterReports(reports, status: ReportStatus.resolved)), [
        'chair',
      ]);
    });

    test('sorts newest, oldest or most backed', () {
      expect(ids(filterReports(reports)), ['tap', 'light', 'chair']);
      expect(ids(filterReports(reports, sort: ReportSort.oldest)), [
        'chair',
        'light',
        'tap',
      ]);
      expect(ids(filterReports(reports, sort: ReportSort.mostBacked)), [
        'light',
        'tap',
        'chair',
      ]);
    });

    test('a report still waiting for its server time counts as newest', () {
      final list = [...reports, report('new')];
      expect(filterReports(list).first.id, 'new');
    });

    test('sort cycles through every option', () {
      expect(ReportSort.newest.next, ReportSort.oldest);
      expect(ReportSort.mostBacked.next, ReportSort.newest);
    });
  });

  test('ReportStats counts open and resolved', () {
    final stats = ReportStats.of(reports);
    expect(stats.open, 2);
    expect(stats.resolved, 1);
  });

  group('buildTimeline', () {
    final created = DateTime(2026, 11, 6, 7, 42);

    ReportUpdate update(ReportStatus s, int hour, {String? note}) =>
        ReportUpdate(
          id: '$hour',
          status: s,
          note: note,
          byUid: 's1',
          byName: 'Jean Habimana',
          byTeam: 'Plumbing',
          createdAt: DateTime(2026, 11, 6, hour),
        );

    test('a new report: submitted is current, the rest upcoming', () {
      final steps = buildTimeline(report('r', createdAt: created), []);
      expect(
        [for (final s in steps) s.state],
        [
          TimelineState.current,
          TimelineState.upcoming,
          TimelineState.upcoming,
          TimelineState.upcoming,
        ],
      );
      expect(steps.first.time, created);
      expect(steps.first.by, isNull);
    });

    test('in progress: earlier steps done, note on the current one', () {
      final steps = buildTimeline(
        report('r', status: ReportStatus.inProgress, createdAt: created),
        [
          update(ReportStatus.underReview, 8, note: 'Looking into it'),
          update(ReportStatus.inProgress, 9, note: 'Plumber on the way'),
        ],
      );
      expect(steps[1].state, TimelineState.done);
      expect(steps[1].note, isNull, reason: 'only the current step has one');
      expect(steps[2].state, TimelineState.current);
      expect(steps[2].by, 'Jean H., Plumbing');
      expect(steps[2].note, 'Plumber on the way');
      expect(steps[3].state, TimelineState.upcoming);
    });

    test('a skipped step still counts as done', () {
      final steps = buildTimeline(
        report('r', status: ReportStatus.inProgress, createdAt: created),
        [update(ReportStatus.inProgress, 9)],
      );
      expect(steps[1].state, TimelineState.done);
      expect(steps[1].time, isNull);
    });

    test('after a reopen each step shows its latest update', () {
      final steps = buildTimeline(
        report('r', status: ReportStatus.underReview, createdAt: created),
        [
          update(ReportStatus.underReview, 8, note: 'first look'),
          update(ReportStatus.underReview, 15, note: 'second look'),
        ],
      );
      expect(steps[1].time!.hour, 15);
      expect(steps[1].note, 'second look');
    });
  });

  test('shortStaffName', () {
    expect(shortStaffName('Jean Habimana', 'Plumbing'), 'Jean H., Plumbing');
    expect(shortStaffName('Jean', null), 'Jean');
    expect(shortStaffName('', 'Electrical'), 'Facilities team, Electrical');
  });
}
