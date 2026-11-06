import '../../../core/models/report_enums.dart';
import '../../reports/data/report.dart';

/// The three tabs of the dashboard's "Report queue".
enum StaffQueue {
  fresh('New'),
  mine('Mine'),
  all('All');

  const StaffQueue(this.label);
  final String label;
}

/// The four tiles at the top of the staff dashboard.
class StaffStats {
  const StaffStats({
    required this.newToday,
    required this.inProgress,
    required this.underReview,
    required this.resolvedThisWeek,
  });

  final int newToday;
  final int inProgress;
  final int underReview;
  final int resolvedThisWeek;

  /// "New today" counts reports sent since midnight that nobody has picked
  /// up yet. "Resolved this week" counts reports resolved in the last 7
  /// days, using the time of their last update.
  factory StaffStats.of(List<Report> reports, {required DateTime now}) {
    final midnight = DateTime(now.year, now.month, now.day);
    final weekAgo = now.subtract(const Duration(days: 7));
    var newToday = 0, inProgress = 0, underReview = 0, resolved = 0;
    for (final r in reports) {
      switch (r.status) {
        case ReportStatus.submitted:
          if (!(r.createdAt ?? now).isBefore(midnight)) newToday++;
        case ReportStatus.underReview:
          underReview++;
        case ReportStatus.inProgress:
          inProgress++;
        case ReportStatus.resolved:
          if (!(r.updatedAt ?? now).isBefore(weekAgo)) resolved++;
      }
    }
    return StaffStats(
      newToday: newToday,
      inProgress: inProgress,
      underReview: underReview,
      resolvedThisWeek: resolved,
    );
  }
}

/// The reports in one queue tab.
///
/// - New: nobody has looked at them yet (still "Submitted").
/// - Mine: assigned to this staff member and not resolved.
/// - All: everything.
///
/// New and Mine put the most urgent first, then the most backed, then the
/// oldest, so what has waited longest isn't buried. All is newest first.
List<Report> staffQueue(
  List<Report> reports, {
  required StaffQueue queue,
  required String uid,
}) {
  final shown = switch (queue) {
    StaffQueue.fresh => [
      for (final r in reports)
        if (r.status == ReportStatus.submitted) r,
    ],
    StaffQueue.mine => [
      for (final r in reports)
        if (r.assignedTo?.uid == uid && r.status != ReportStatus.resolved) r,
    ],
    StaffQueue.all => [...reports],
  };
  final far = DateTime.fromMillisecondsSinceEpoch(0);
  if (queue == StaffQueue.all) {
    shown.sort((a, b) => (b.createdAt ?? far).compareTo(a.createdAt ?? far));
  } else {
    shown.sort((a, b) {
      final byUrgency = b.urgency.index.compareTo(a.urgency.index);
      if (byUrgency != 0) return byUrgency;
      final byBackers = b.meTooCount.compareTo(a.meTooCount);
      if (byBackers != 0) return byBackers;
      return (a.createdAt ?? far).compareTo(b.createdAt ?? far);
    });
  }
  return shown;
}
