import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/neu_card.dart';
import '../../../core/widgets/neu_switch.dart';
import '../../notifications/application/notification_providers.dart';
import '../../reports/application/report_actions.dart';
import '../../reports/presentation/widgets/report_widgets.dart';
import 'widgets/profile_widgets.dart';

/// Shared layout for the pages opened from Profile.
class _SubPage extends StatelessWidget {
  const _SubPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.screen,
            AppSpacing.screen,
            AppSpacing.navClearance,
          ),
          children: [
            SubPageHeader(title: title),
            const SizedBox(height: AppSpacing.section),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Reports the student said "Me too" to.
class FollowedReportsScreen extends ConsumerWidget {
  const FollowedReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(followedReportsProvider);
    return _SubPage(
      title: 'Followed reports',
      children: [
        AsyncValueView(
          value: followed,
          onRetry: () => ref.invalidate(followingIdsProvider),
          data: (reports) => reports.isEmpty
              ? const EmptyState(
                  title: 'Not following anything yet',
                  message:
                      'Tap "Me too" on a report you also see, and it shows up '
                      "here. You'll be told when staff update it.",
                )
              : ReportCardList(reports: reports, showMeToo: true),
        ),
      ],
    );
  }
}

/// What the Notifications list includes. Saved on the phone.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settings = ref.watch(notificationSettingsProvider);
    final controller = ref.read(notificationSettingsProvider.notifier);
    return _SubPage(
      title: 'Notification settings',
      children: [
        SettingsGroup(
          children: [
            SettingsRow(
              label: 'Reports I back',
              detail: 'Updates on reports you said "Me too" to',
              trailing: NeuSwitch(
                value: settings.backedReports,
                semanticLabel: 'Updates on reports I back',
                onChanged: controller.setBackedReports,
              ),
            ),
            SettingsRow(
              label: 'Campus announcements',
              detail: 'Notices from the facilities office',
              trailing: NeuSwitch(
                value: settings.announcements,
                semanticLabel: 'Campus announcements',
                onChanged: controller.setAnnouncements,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Updates on reports you sent are always shown. Notifications '
          'appear inside the app; Ripoti does not send push messages.',
          style: AppText.meta.copyWith(fontSize: 13, color: c.textSecondary),
        ),
      ],
    );
  }
}

/// Short answers to what students and staff ask most.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faq = [
    (
      'What should I report?',
      'Anything broken or unsafe on campus: water, power, furniture, '
          'sanitation or safety problems. For emergencies, call campus '
          'security first.',
    ),
    (
      'Who sees my name?',
      'Staff and other students see your name on reports you send. Turn '
          'on "Report anonymously" and no name or account id is stored on '
          'the report at all. Only you can see it in My reports.',
    ),
    (
      'What does "Me too" do?',
      'It tells staff more people are affected, which helps them decide '
          'what to fix first. You also get the updates on that report. Tap '
          '"Added" to take your support back.',
    ),
    (
      'Why is my report "Under review"?',
      'Campus staff have seen it and are deciding who will fix it. The '
          'timeline on the report shows every step and any notes from staff.',
    ),
    (
      'It was marked resolved but it isn\'t fixed.',
      'Open the report and tap "Reopen", then say what\'s still wrong. It '
          'goes back to staff. If it is fixed, tap "Yes, fixed".',
    ),
    (
      'I\'m staff. Why can\'t I update reports?',
      'Staff accounts are approved by the facilities office. Ask them to '
          'approve your account, then sign out and back in.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _SubPage(
      title: 'Help and FAQ',
      children: [
        for (final (q, a) in _faq) ...[
          NeuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    q,
                    style: AppText.bodyStrong.copyWith(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  a,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    height: 1.5,
                    color: c.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.listGap),
        ],
      ],
    );
  }
}
