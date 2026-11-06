import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../auth/application/auth_providers.dart';
import '../../reports/application/report_filters.dart';
import '../../reports/application/report_providers.dart';
import 'widgets/profile_widgets.dart';

/// Student profile: who they are, their report counts, links and settings.
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profile = ref.watch(sessionProvider).profile;
    final mine = ref.watch(myReportsProvider).value;
    final stats = mine == null ? null : ReportStats.of(mine);
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
              roleLabel: 'Student',
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: count(mine?.length),
                    label: 'Reported',
                    compact: true,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StatTile(
                    value: count(stats?.open),
                    label: 'Open',
                    valueColor: c.amberLight,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StatTile(
                    value: count(stats?.resolved),
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
                  label: 'My reports',
                  onTap: () {
                    ref
                        .read(browseFiltersProvider.notifier)
                        .open(scope: BrowseScope.mine);
                    context.go(Routes.reports);
                  },
                ),
                SettingsRow(
                  label: 'Followed reports',
                  onTap: () => context.push(Routes.followedReports),
                ),
                SettingsRow(
                  label: 'Notification settings',
                  onTap: () => context.push(Routes.notificationSettings),
                ),
                const DarkModeRow(),
                SettingsRow(
                  label: 'Help and FAQ',
                  onTap: () => context.push(Routes.help),
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
