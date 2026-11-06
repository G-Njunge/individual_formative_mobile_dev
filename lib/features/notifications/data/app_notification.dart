import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/report_enums.dart';
import '../../reports/data/report.dart';

/// "is now In progress" or "left a note".
enum NotificationKind {
  status,
  note;

  static NotificationKind fromValue(String? value) =>
      value == 'note' ? NotificationKind.note : NotificationKind.status;
}

/// One row on the Notifications screen.
///
/// Stores facts, not sentences, so the screen decides the wording and
/// colours ("#1042 is now **In progress**"). Comes from one of two places:
/// - `users/{uid}/notifications`, written by staff for named reporters and
///   supporters;
/// - built on the phone from the timeline of the student's anonymous
///   reports, because staff can't address an anonymous reporter
///   ([fromAnonymousUpdate]).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.reportId,
    required this.ticketNumber,
    required this.reportTitle,
    required this.status,
    this.note,
    required this.read,
    this.createdAt,
    this.fromAnonymousReport = false,
  });

  final String id;
  final NotificationKind kind;
  final String reportId;
  final int ticketNumber;
  final String reportTitle;

  /// The report's status after the update.
  final ReportStatus status;
  final String? note;
  final bool read;
  final DateTime? createdAt;

  /// Built on the phone for one of the student's anonymous reports. Marking
  /// it read updates their private link to the report, not a document here.
  final bool fromAnonymousReport;

  factory AppNotification.fromJson(String id, Map<String, dynamic> json) {
    final note = (json['note'] as String?)?.trim();
    return AppNotification(
      id: id,
      kind: NotificationKind.fromValue(json['type'] as String?),
      reportId: (json['reportId'] as String?) ?? '',
      ticketNumber: (json['ticketNumber'] as num?)?.toInt() ?? 0,
      reportTitle: (json['reportTitle'] as String?) ?? '',
      status: ReportStatus.fromValue(json['status'] as String?),
      note: note == null || note.isEmpty ? null : note,
      read: (json['read'] as bool?) ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// A staff update on an anonymous report, as a notification. Read when the
  /// student last looked at that report's updates after it was made.
  factory AppNotification.fromAnonymousUpdate(
    Report report,
    ReportUpdate update, {
    DateTime? seenAt,
  }) {
    final at = update.createdAt;
    return AppNotification(
      id: 'anonymous:${report.id}:${update.id}',
      kind: update.previousStatus == null || update.changedStatus
          ? NotificationKind.status
          : NotificationKind.note,
      reportId: report.id,
      ticketNumber: report.ticketNumber,
      reportTitle: report.title,
      status: update.status,
      note: update.note,
      read: seenAt != null && at != null && !at.isAfter(seenAt),
      createdAt: at,
      fromAnonymousReport: true,
    );
  }

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    kind: kind,
    reportId: reportId,
    ticketNumber: ticketNumber,
    reportTitle: reportTitle,
    status: status,
    note: note,
    read: read ?? this.read,
    createdAt: createdAt,
    fromAnonymousReport: fromAnonymousReport,
  );
}

/// `announcements/{id}`, posted by staff from their Profile.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.byName,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String byName;
  final DateTime? createdAt;

  factory Announcement.fromJson(String id, Map<String, dynamic> json) =>
      Announcement(
        id: id,
        title: (json['title'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        byName: (json['byName'] as String?) ?? '',
        createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      );
}
