import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/models/report_enums.dart';
import 'package:individual_formative/features/notifications/application/notification_feed.dart';
import 'package:individual_formative/features/notifications/data/app_notification.dart';
import 'package:individual_formative/features/reports/data/report.dart';

final now = DateTime(2026, 11, 6, 15);

AppNotification note(
  String id, {
  String reportId = 'mine',
  ReportStatus status = ReportStatus.inProgress,
  NotificationKind kind = NotificationKind.status,
  bool read = false,
  int hoursAgo = 1,
}) => AppNotification(
  id: id,
  kind: kind,
  reportId: reportId,
  ticketNumber: 1042,
  reportTitle: 'Leaking tap',
  status: status,
  read: read,
  createdAt: now.subtract(Duration(hours: hoursAgo)),
);

Report report(
  String id, {
  ReportStatus status = ReportStatus.resolved,
  bool confirmed = false,
}) => Report(
  id: id,
  ticketNumber: 1042,
  title: 'Leaking tap',
  description: '',
  category: ReportCategory.water,
  location: 'Block C',
  urgency: Urgency.medium,
  status: status,
  reporterId: 'u1',
  confirmed: confirmed,
);

NotificationFeed feed({
  List<AppNotification> stored = const [],
  List<AppNotification> anonymous = const [],
  Map<String, Report>? mine = const {},
  NotificationSettings settings = const NotificationSettings(),
  Announcement? announcement,
}) => buildNotificationFeed(
  stored: stored,
  anonymous: anonymous,
  myReports: mine,
  settings: settings,
  announcement: announcement,
  now: now,
);

void main() {
  test('joins stored and phone-built notifications, newest first', () {
    final f = feed(
      stored: [note('old', hoursAgo: 5), note('new', hoursAgo: 1)],
      anonymous: [note('middle', hoursAgo: 3, read: true)],
      mine: {'mine': report('mine', status: ReportStatus.inProgress)},
    );
    expect(
      [for (final i in f.items) i.notification.id],
      ['new', 'middle', 'old'],
    );
    expect(f.unreadCount, 2);
  });

  test('"Reports I back" off hides other people\'s reports only', () {
    final f = feed(
      stored: [
        note('backed', reportId: 'theirs'),
        note('own'),
      ],
      mine: {'mine': report('mine')},
      settings: const NotificationSettings(backedReports: false),
    );
    expect([for (final i in f.items) i.notification.id], ['own']);
  });

  test('nothing is hidden while the student\'s own reports are loading', () {
    final f = feed(
      stored: [note('a', reportId: 'theirs')],
      mine: null,
      settings: const NotificationSettings(backedReports: false),
    );
    expect(f.items, hasLength(1));
    expect(f.items.single.askIfFixed, isFalse);
  });

  group('"Is it fixed?"', () {
    final resolvedTwice = [
      note('latest', status: ReportStatus.resolved, hoursAgo: 1),
      note('earlier', status: ReportStatus.resolved, hoursAgo: 30),
    ];

    test('asks once, on the newest resolved notice of my own report', () {
      final f = feed(stored: resolvedTwice, mine: {'mine': report('mine')});
      expect([for (final i in f.items) i.askIfFixed], [true, false]);
    });

    test('stops asking once confirmed or reopened', () {
      for (final r in [
        report('mine', confirmed: true),
        report('mine', status: ReportStatus.submitted),
      ]) {
        final f = feed(stored: resolvedTwice, mine: {'mine': r});
        expect(f.items.any((i) => i.askIfFixed), isFalse);
      }
    });

    test('never asks supporters', () {
      final f = feed(
        stored: [note('x', reportId: 'theirs', status: ReportStatus.resolved)],
        mine: {'mine': report('mine')},
      );
      expect(f.items.single.askIfFixed, isFalse);
      expect(f.items.single.aboutMyReport, isFalse);
    });
  });

  test('shows a recent announcement unless switched off', () {
    final recent = Announcement(
      id: 'a',
      title: 'Water cut on Saturday',
      body: '',
      byName: 'Jean',
      createdAt: now.subtract(const Duration(days: 3)),
    );
    final old = Announcement(
      id: 'b',
      title: 'Old news',
      body: '',
      byName: 'Jean',
      createdAt: now.subtract(const Duration(days: 20)),
    );
    expect(feed(announcement: recent).announcement, recent);
    expect(feed(announcement: old).announcement, isNull);
    expect(
      feed(
        announcement: recent,
        settings: const NotificationSettings(announcements: false),
      ).announcement,
      isNull,
    );
  });

  group('AppNotification.fromAnonymousUpdate', () {
    final r = report('anon', status: ReportStatus.inProgress);
    ReportUpdate update(ReportStatus from, ReportStatus to) => ReportUpdate(
      id: 'u',
      status: to,
      previousStatus: from,
      note: 'Plumber on the way',
      byUid: 's1',
      byName: 'Jean',
      createdAt: now.subtract(const Duration(hours: 2)),
    );

    test('a status change or a note', () {
      final moved = AppNotification.fromAnonymousUpdate(
        r,
        update(ReportStatus.submitted, ReportStatus.inProgress),
      );
      final noted = AppNotification.fromAnonymousUpdate(
        r,
        update(ReportStatus.inProgress, ReportStatus.inProgress),
      );
      expect(moved.kind, NotificationKind.status);
      expect(noted.kind, NotificationKind.note);
      expect(moved.fromAnonymousReport, isTrue);
      expect(moved.ticketNumber, 1042);
    });

    test('read once the report was opened after the update', () {
      final u = update(ReportStatus.submitted, ReportStatus.inProgress);
      expect(AppNotification.fromAnonymousUpdate(r, u).read, isFalse);
      expect(
        AppNotification.fromAnonymousUpdate(
          r,
          u,
          seenAt: now.subtract(const Duration(hours: 3)),
        ).read,
        isFalse,
      );
      expect(
        AppNotification.fromAnonymousUpdate(r, u, seenAt: now).read,
        isTrue,
      );
    });
  });
}
