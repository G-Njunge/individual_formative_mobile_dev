import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/report_enums.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/neu_card.dart';
import '../../../core/widgets/neu_surface.dart';
import '../../reports/presentation/widgets/fix_check.dart';
import '../application/notification_feed.dart';
import '../application/notification_providers.dart';
import '../data/app_notification.dart';

/// Campus announcement, then the student's notifications grouped into
/// Today and Earlier. Unread rows are bold with an amber dot.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(notificationFeedProvider);
    final unread = feed.value?.unreadCount ?? 0;
    // Watched so the controller stays alive while it saves.
    ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    void open(AppNotification n) {
      controller.markRead([n]);
      context.push(Routes.reportDetails(n.reportId));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.section,
            AppSpacing.screen,
            AppSpacing.navClearance,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: const Text(
                      'Notifications',
                      style: AppText.screenTitle,
                    ),
                  ),
                ),
                TextLinkButton(
                  label: 'Mark all read',
                  onPressed: unread == 0
                      ? null
                      : () => controller.markRead([
                          for (final i in feed.value!.items) i.notification,
                        ]),
                ),
              ],
            ),
            const SizedBox(height: 22),
            AsyncValueView(
              value: feed,
              onRetry: () => ref.invalidate(inboxProvider),
              data: (f) {
                final today = [
                  for (final i in f.items)
                    if (TimeFormat.isToday(
                      i.notification.createdAt ?? DateTime.now(),
                    ))
                      i,
                ];
                final earlier = [
                  for (final i in f.items)
                    if (!today.contains(i)) i,
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (f.announcement case final a?) ...[
                      _AnnouncementCard(announcement: a),
                      const SizedBox(height: AppSpacing.section),
                    ],
                    if (f.items.isEmpty)
                      const EmptyState(
                        title: 'No notifications yet',
                        message:
                            'When staff update a report you sent or backed, '
                            "you'll see it here.",
                      ),
                    for (final (label, group) in [
                      ('TODAY', today),
                      ('EARLIER', earlier),
                    ])
                      if (group.isNotEmpty) ...[
                        _GroupLabel(label),
                        for (final item in group) ...[
                          _NotificationRow(
                            item: item,
                            onTap: () => open(item.notification),
                          ),
                          const SizedBox(height: AppSpacing.listGap),
                        ],
                        const SizedBox(height: 10),
                      ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: AppText.categoryLabel.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    ),
  );
}

/// Filled amber "CAMPUS ANNOUNCEMENT" card.
class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: 'Campus announcement',
      child: NeuSurface(
        color: c.amber,
        radius: AppRadii.card,
        shadow: NeuShadow.large,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CAMPUS ANNOUNCEMENT',
              style: AppText.categoryLabel.copyWith(color: c.onAmber),
            ),
            const SizedBox(height: 8),
            Text(
              announcement.title,
              style: AppText.cardTitle.copyWith(
                fontSize: 16.5,
                height: 1.35,
                color: c.onAmber,
              ),
            ),
            if (announcement.body.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                announcement.body,
                style: AppText.body.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  color: c.onAmber,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One notification. The wording is built here from the stored facts.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = item.notification;
    final unread = !n.read;
    final weight = unread ? FontWeight.w800 : FontWeight.w500;
    final base = AppText.bodyStrong.copyWith(
      fontSize: 15,
      height: 1.4,
      fontWeight: weight,
    );
    final statusStyle = base.copyWith(
      color: n.status.color(c),
      fontWeight: FontWeight.w800,
    );
    final ticket = '#${n.ticketNumber}';
    final time = n.createdAt == null
        ? 'Just now'
        : TimeFormat.shortClock(n.createdAt!);

    final (List<InlineSpan> title, String subtitle) = switch (n.kind) {
      NotificationKind.note => (
        [TextSpan(text: 'Facilities left a note: “${n.note ?? ''}”')],
        '$ticket · $time',
      ),
      NotificationKind.status when n.status == ReportStatus.resolved => (
        [
          TextSpan(text: '$ticket was marked '),
          TextSpan(text: n.status.label, style: statusStyle),
          TextSpan(text: item.askIfFixed ? '. Is it fixed?' : '.'),
        ],
        '${n.reportTitle} · $time',
      ),
      NotificationKind.status => (
        [
          TextSpan(text: '$ticket is now '),
          TextSpan(text: n.status.label, style: statusStyle),
        ],
        '${n.reportTitle} · $time',
      ),
    };
    final plain = [for (final s in title) (s as TextSpan).text].join();

    return NeuCard(
      onTap: onTap,
      semanticLabel:
          '${unread ? 'Unread. ' : ''}$plain. $subtitle'
          '${item.aboutMyReport ? '' : '. A report you backed'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(TextSpan(children: title), style: base),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.meta.copyWith(
                        fontSize: 13,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: c.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (item.askIfFixed) ...[
            const SizedBox(height: 16),
            FixCheckButtons(reportId: n.reportId),
          ],
        ],
      ),
    );
  }
}
