import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/models/report_enums.dart';
import 'package:individual_formative/features/reports/data/report.dart';
import 'package:individual_formative/features/staff/application/staff_queue.dart';

final now = DateTime(2026, 11, 6, 15);

Report report(
  String id, {
  ReportStatus status = ReportStatus.submitted,
  Urgency urgency = Urgency.medium,
  int meToo = 0,
  DateTime? created,
  DateTime? updated,
  String? assignee,
}) => Report(
  id: id,
  ticketNumber: 1000,
  title: id,
  description: '',
  category: ReportCategory.water,
  location: 'Block C',
  urgency: urgency,
  status: status,
  reporterId: 'u1',
  meTooCount: meToo,
  assignedTo: assignee == null ? null : Assignee(uid: assignee, name: 'X'),
  createdAt: created ?? now.subtract(const Duration(hours: 1)),
  updatedAt: updated ?? now,
);

void main() {
  test('StaffStats counts each tile', () {
    final stats = StaffStats.of([
      report('today'),
      report('yesterday', created: now.subtract(const Duration(days: 1))),
      report('review', status: ReportStatus.underReview),
      report('work1', status: ReportStatus.inProgress),
      report('work2', status: ReportStatus.inProgress),
      report('fixed', status: ReportStatus.resolved),
      report(
        'old fix',
        status: ReportStatus.resolved,
        updated: now.subtract(const Duration(days: 8)),
      ),
    ], now: now);
    expect(stats.newToday, 1);
    expect(stats.underReview, 1);
    expect(stats.inProgress, 2);
    expect(stats.resolvedThisWeek, 1);
  });

  group('staffQueue', () {
    final reports = [
      report('low', urgency: Urgency.low),
      report('high old', urgency: Urgency.high, created: DateTime(2026, 11, 1)),
      report('high new', urgency: Urgency.high, created: DateTime(2026, 11, 5)),
      report('high backed', urgency: Urgency.high, meToo: 9),
      report('mine', status: ReportStatus.inProgress, assignee: 's1'),
      report('mine done', status: ReportStatus.resolved, assignee: 's1'),
      report('theirs', status: ReportStatus.inProgress, assignee: 's2'),
    ];

    List<String> ids(StaffQueue q) => [
      for (final r in staffQueue(reports, queue: q, uid: 's1')) r.id,
    ];

    test('New: untouched reports, most urgent and backed first', () {
      expect(ids(StaffQueue.fresh), [
        'high backed',
        'high old',
        'high new',
        'low',
      ]);
    });

    test('Mine: assigned to me and not resolved', () {
      expect(ids(StaffQueue.mine), ['mine']);
    });

    test('All: everything', () {
      expect(ids(StaffQueue.all), hasLength(reports.length));
    });
  });
}
