import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/user_facing_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/storage/shared_preferences_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../reports/application/report_providers.dart';
import '../../reports/data/report.dart';
import '../../reports/data/report_repository.dart';
import '../data/app_notification.dart';
import '../data/notification_repository.dart';
import 'notification_feed.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(firestoreProvider)),
);

/// Notifications staff wrote for the signed-in person.
final inboxProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchInbox(uid);
});

final latestAnnouncementProvider = StreamProvider.autoDispose<Announcement?>(
  (ref) => ref.watch(notificationRepositoryProvider).watchLatestAnnouncement(),
);

/// When the student last read the updates on each anonymous report.
final anonymousSeenProvider =
    StreamProvider.autoDispose<Map<String, DateTime?>>((ref) {
      final uid = ref.watch(currentUidProvider);
      if (uid == null) return Stream.value(const {});
      return ref.watch(reportRepositoryProvider).watchAnonymousSeen(uid);
    });

/// Staff updates on the student's anonymous reports, as (report, update)
/// pairs. Staff never learn who sent these reports, so they can't write
/// notifications for them; the student's phone builds them from the
/// timeline instead. The reporter's own "Reopen" entries are left out.
final _anonymousUpdatesProvider =
    StreamProvider.autoDispose<List<(Report, ReportUpdate)>>((ref) {
      final reports = ref.watch(myAnonymousReportsProvider).value;
      if (reports == null) return const Stream.empty();
      if (reports.isEmpty) return Stream.value(const []);
      final repo = ref.watch(reportRepositoryProvider);
      return ReportRepository.combineLatestLists([
        for (final r in reports)
          repo
              .watchUpdates(r.id)
              .map(
                (updates) => [
                  for (final u in updates)
                    if (u.createdAt != null &&
                        u.byName != ReportRepository.reopenedBy)
                      (r, u),
                ],
              ),
      ]);
    });

/// The switches on "Notification settings", saved on the phone.
class NotificationSettingsController extends Notifier<NotificationSettings> {
  static const _backedKey = 'notify_backed_reports';
  static const _announcementsKey = 'notify_announcements';

  @override
  NotificationSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return NotificationSettings(
      backedReports: prefs.getBool(_backedKey) ?? true,
      announcements: prefs.getBool(_announcementsKey) ?? true,
    );
  }

  Future<void> setBackedReports(bool on) async {
    state = state.copyWith(backedReports: on);
    await ref.read(sharedPreferencesProvider).setBool(_backedKey, on);
  }

  Future<void> setAnnouncements(bool on) async {
    state = state.copyWith(announcements: on);
    await ref.read(sharedPreferencesProvider).setBool(_announcementsKey, on);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsController, NotificationSettings>(
      NotificationSettingsController.new,
    );

/// Everything the Notifications screen shows.
final notificationFeedProvider =
    Provider.autoDispose<AsyncValue<NotificationFeed>>((ref) {
      final stored = ref.watch(inboxProvider);
      final anonymous = ref.watch(_anonymousUpdatesProvider);
      final seen = ref.watch(anonymousSeenProvider).value ?? const {};
      final mine = ref.watch(myReportsProvider).value;
      final settings = ref.watch(notificationSettingsProvider);
      final announcement = ref.watch(latestAnnouncementProvider).value;

      if (stored case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      if (stored.value == null) return const AsyncLoading();
      return AsyncData(
        buildNotificationFeed(
          stored: stored.value!,
          anonymous: [
            for (final (report, update)
                in anonymous.value ?? const <(Report, ReportUpdate)>[])
              AppNotification.fromAnonymousUpdate(
                report,
                update,
                seenAt: seen[report.id],
              ),
          ],
          myReports: mine == null ? null : {for (final r in mine) r.id: r},
          settings: settings,
          announcement: announcement,
          now: DateTime.now(),
        ),
      );
    });

/// The amber dot on the Notifications tab.
final hasUnreadNotificationsProvider = Provider.autoDispose<bool>(
  (ref) => (ref.watch(notificationFeedProvider).value?.unreadCount ?? 0) > 0,
);

/// "Mark all read" and opening one notification.
class NotificationsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> markRead(Iterable<AppNotification> notifications) async {
    final uid = ref.read(currentUidProvider);
    final unread = notifications.where((n) => !n.read).toList();
    if (uid == null || unread.isEmpty) return;
    final inbox = ref.read(notificationRepositoryProvider);
    final reports = ref.read(reportRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await Future.wait([
        inbox.markRead(uid, [
          for (final n in unread)
            if (!n.fromAnonymousReport) n.id,
        ]),
        reports.markAnonymousSeen(uid, {
          for (final n in unread)
            if (n.fromAnonymousReport) n.reportId,
        }),
      ]);
    });
    if (ref.mounted) state = result;
  }
}

final notificationsControllerProvider =
    NotifierProvider.autoDispose<NotificationsController, AsyncValue<void>>(
      NotificationsController.new,
    );

/// Staff "Post an announcement".
class AnnouncementController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> post({required String title, required String body}) async {
    final by = ref.read(sessionProvider).profile;
    if (by == null || state.isLoading) return false;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      if (!by.canUseStaffFeatures) {
        throw const UserFacingException('Only staff can post announcements.');
      }
      await ref
          .read(notificationRepositoryProvider)
          .postAnnouncement(title: title, body: body, by: by);
    });
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

final announcementControllerProvider =
    NotifierProvider.autoDispose<AnnouncementController, AsyncValue<void>>(
      AnnouncementController.new,
    );
