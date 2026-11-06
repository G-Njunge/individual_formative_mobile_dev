import '../../../core/models/report_enums.dart';
import '../../reports/data/report.dart';
import '../data/app_notification.dart';

/// What "Notification settings" on Profile controls. There are no push
/// messages (they need Cloud Functions), so these decide what the
/// Notifications list and the unread dot include. Updates on the student's
/// own reports are always shown.
class NotificationSettings {
  const NotificationSettings({
    this.backedReports = true,
    this.announcements = true,
  });

  /// Updates on reports the student said "Me too" to.
  final bool backedReports;

  /// The campus announcement card.
  final bool announcements;

  NotificationSettings copyWith({bool? backedReports, bool? announcements}) =>
      NotificationSettings(
        backedReports: backedReports ?? this.backedReports,
        announcements: announcements ?? this.announcements,
      );
}

class NotificationItem {
  const NotificationItem({
    required this.notification,
    required this.aboutMyReport,
    this.askIfFixed = false,
  });

  final AppNotification notification;

  /// The student sent this report (named or anonymously), rather than
  /// backing someone else's.
  final bool aboutMyReport;

  /// Show "Is it fixed?" with "Yes, fixed" and "Reopen". Only on the newest
  /// "Resolved" notification of the student's own report, and only while
  /// the report is still waiting for their answer.
  final bool askIfFixed;
}

class NotificationFeed {
  const NotificationFeed({required this.items, this.announcement});

  final List<NotificationItem> items;
  final Announcement? announcement;

  int get unreadCount => items.where((i) => !i.notification.read).length;
}

/// Announcements older than this aren't shown.
const announcementShownFor = Duration(days: 14);

/// Joins stored and phone-built notifications into one list, newest first,
/// applying the student's settings.
NotificationFeed buildNotificationFeed({
  required List<AppNotification> stored,
  required List<AppNotification> anonymous,

  /// The student's own reports by id. Null while they are still loading:
  /// then nothing is hidden by the "backed" switch and no prompts show.
  required Map<String, Report>? myReports,
  required NotificationSettings settings,
  Announcement? announcement,
  required DateTime now,
}) {
  final all = [...stored, ...anonymous]
    ..sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));

  final asked = <String>{};
  final items = <NotificationItem>[];
  for (final n in all) {
    final mine = myReports?[n.reportId];
    final backed = myReports != null && mine == null;
    if (backed && !settings.backedReports) continue;
    final ask =
        mine != null &&
        mine.awaitsConfirmation &&
        n.kind == NotificationKind.status &&
        n.status == ReportStatus.resolved &&
        asked.add(n.reportId);
    items.add(
      NotificationItem(
        notification: n,
        aboutMyReport: !backed,
        askIfFixed: ask,
      ),
    );
  }

  final recent =
      announcement != null &&
      settings.announcements &&
      now.difference(announcement.createdAt ?? now) <= announcementShownFor;
  return NotificationFeed(
    items: items,
    announcement: recent ? announcement : null,
  );
}
