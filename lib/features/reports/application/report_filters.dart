import '../../../core/models/report_enums.dart';
import '../data/report.dart';

/// Order of the Browse list. The "Newest first" control cycles through them.
enum ReportSort {
  newest('Newest first'),
  oldest('Oldest first'),
  mostBacked('Most me too');

  const ReportSort(this.label);

  final String label;

  ReportSort get next => values[(index + 1) % values.length];
}

/// Search, status filter and sort, applied on the device.
///
/// Firestore can't search inside text, so the lists load once (live) and
/// are narrowed here. Matching ignores case and checks the title and the
/// location, which is what people type ("tap", "Block C").
List<Report> filterReports(
  List<Report> reports, {
  String query = '',
  ReportStatus? status,
  ReportSort sort = ReportSort.newest,
}) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  final result = reports.where((r) {
    if (status != null && r.status != status) return false;
    if (words.isEmpty) return true;
    final haystack = '${r.title} ${r.location}'.toLowerCase();
    return words.every(haystack.contains);
  }).toList();

  // Reports whose server timestamp hasn't arrived yet are the newest.
  final far = DateTime(9999);
  int byDate(Report a, Report b) =>
      (a.createdAt ?? far).compareTo(b.createdAt ?? far);

  switch (sort) {
    case ReportSort.newest:
      result.sort((a, b) => byDate(b, a));
    case ReportSort.oldest:
      result.sort(byDate);
    case ReportSort.mostBacked:
      result.sort((a, b) {
        final byCount = b.meTooCount.compareTo(a.meTooCount);
        return byCount != 0 ? byCount : byDate(b, a);
      });
  }
  return result;
}

/// The two numbers on Home.
class ReportStats {
  const ReportStats({required this.open, required this.resolved});

  factory ReportStats.of(List<Report> reports) => ReportStats(
    open: reports.where((r) => r.status.isOpen).length,
    resolved: reports.where((r) => !r.status.isOpen).length,
  );

  final int open;
  final int resolved;
}

enum TimelineState { done, current, upcoming }

/// One step of the progress timeline on Report details.
class TimelineEntry {
  const TimelineEntry({
    required this.status,
    required this.state,
    this.time,
    this.by,
    this.note,
  });

  final ReportStatus status;
  final TimelineState state;

  /// When the report reached this step. Null for steps not reached yet.
  final DateTime? time;

  /// Who moved it here ("Jean H., Plumbing"). Null for the reporter's own
  /// submission and for steps not reached yet.
  final String? by;

  /// The staff note left with the current step, if any.
  final String? note;
}

/// Builds the four steps (Submitted, Under review, In progress, Resolved)
/// from the report and its staff updates.
///
/// Every step before the current status counts as done, even if staff
/// skipped it (Submitted straight to In progress). Each step shows its most
/// recent update, so after a reopen the timeline shows the latest round.
List<TimelineEntry> buildTimeline(Report report, List<ReportUpdate> updates) {
  final latest = <ReportStatus, ReportUpdate>{};
  for (final u in updates) {
    latest[u.status] = u;
  }

  return [
    for (final s in ReportStatus.values)
      if (s.index < report.status.index)
        _entry(report, s, latest[s], TimelineState.done)
      else if (s == report.status)
        _entry(report, s, latest[s], TimelineState.current)
      else
        TimelineEntry(status: s, state: TimelineState.upcoming),
  ];
}

TimelineEntry _entry(
  Report report,
  ReportStatus status,
  ReportUpdate? update,
  TimelineState state,
) {
  if (status == ReportStatus.submitted && update == null) {
    return TimelineEntry(status: status, state: state, time: report.createdAt);
  }
  return TimelineEntry(
    status: status,
    state: state,
    time: update?.createdAt,
    by: update == null ? null : shortStaffName(update.byName, update.byTeam),
    note: state == TimelineState.current ? update?.note : null,
  );
}

/// "Jean Habimana" in "Plumbing" becomes "Jean H., Plumbing".
String shortStaffName(String name, String? team) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final short = parts.length > 1
      ? '${parts.first} ${parts.last[0].toUpperCase()}.'
      : parts.first;
  final who = short.isEmpty ? 'Facilities team' : short;
  return team == null || team.isEmpty ? who : '$who, $team';
}
