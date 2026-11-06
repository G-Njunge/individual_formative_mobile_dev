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
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/neu_text_field.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../auth/application/auth_providers.dart';
import '../../notifications/application/notification_providers.dart';
import '../../notifications/data/notification_repository.dart';
import '../../reports/application/report_providers.dart';
import 'widgets/profile_widgets.dart';

/// Staff profile: who they are, the reports assigned to them, posting a
/// campus announcement, and settings. Not in the design; built from the
/// same parts as the student Profile.
class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profile = ref.watch(sessionProvider).profile;
    final reports = ref.watch(allReportsProvider).value;
    final latest = ref.watch(latestAnnouncementProvider).value;
    final mine = reports
        ?.where((r) => r.assignedTo?.uid == profile?.uid)
        .toList();
    String count(int? n) => n == null ? '–' : '$n';

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
            Semantics(
              header: true,
              child: const Text('Profile', style: AppText.screenTitle),
            ),
            const SizedBox(height: 26),
            ProfileHeader(
              name: profile?.name ?? '',
              email: profile?.email ?? '',
              roleLabel: [
                'Staff',
                if (profile?.team case final t? when t.isNotEmpty) t,
              ].join(' · '),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: count(mine?.where((r) => r.status.isOpen).length),
                    label: 'Assigned',
                    valueColor: c.amberLight,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StatTile(
                    value: count(
                      mine
                          ?.where((r) => r.status == ReportStatus.resolved)
                          .length,
                    ),
                    label: 'Resolved',
                    valueColor: c.teal,
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SettingsGroup(
              children: [
                SettingsRow(
                  label: 'Post an announcement',
                  detail: latest == null
                      ? 'Shown to every student in Notifications'
                      : 'Latest: ${latest.title}'
                            '${latest.createdAt == null ? '' : ' · ${TimeFormat.shortClock(latest.createdAt!)}'}',
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const _AnnouncementSheet(),
                  ),
                ),
                const DarkModeRow(),
                SettingsRow(
                  label: 'Help and FAQ',
                  onTap: () => context.push(Routes.staffHelp),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SignOutButton(),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementSheet extends ConsumerStatefulWidget {
  const _AnnouncementSheet();

  @override
  ConsumerState<_AnnouncementSheet> createState() => _AnnouncementSheetState();
}

class _AnnouncementSheetState extends ConsumerState<_AnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(announcementControllerProvider.notifier)
        .post(title: _title.text, body: _body.text);
    if (!ok || !mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Announcement posted.')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(announcementControllerProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: const Text(
                    'Post an announcement',
                    style: AppText.sectionHeading,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Every student sees it at the top of Notifications for two '
                  'weeks, or until a newer one is posted.',
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                NeuTextField(
                  label: 'Title',
                  hint: 'e.g. Planned water cut in Hostel A on Saturday',
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: NotificationRepository.maxAnnouncementTitle,
                  enabled: !state.isLoading,
                  validator: (v) => (v?.trim().length ?? 0) < 5
                      ? 'Give it a short title'
                      : null,
                ),
                const SizedBox(height: 16),
                NeuTextField(
                  label: 'Details (optional)',
                  hint:
                      'e.g. 9:00 to 12:00. Store some water the night before.',
                  controller: _body,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 3,
                  maxLength: NotificationRepository.maxAnnouncementBody,
                  enabled: !state.isLoading,
                ),
                if (state.hasError) ...[
                  const SizedBox(height: 14),
                  FormMessage(friendlyErrorMessage(state.error!)),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Post',
                  loading: state.isLoading,
                  onPressed: _post,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
