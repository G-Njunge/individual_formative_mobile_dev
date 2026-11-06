import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/segmented_toggle.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../auth/application/auth_providers.dart';
import '../../reports/application/report_providers.dart';
import '../application/staff_providers.dart';
import '../application/staff_queue.dart';
import 'widgets/staff_widgets.dart';

/// "Facilities desk": counts across campus, then the report queue.
class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() =>
      _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  StaffQueue _queue = StaffQueue.fresh;

  @override
  void initState() {
    super.initState();
    // Picks up the staff flag set on approval now, so the first "Save
    // update" doesn't have to wait for a token refresh.
    Future.microtask(() => ref.read(staffAccessCheckProvider)());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profile = ref.watch(sessionProvider).profile;
    final reports = ref.watch(allReportsProvider);
    final stats = reports.value == null
        ? null
        : StaffStats.of(reports.value!, now: DateTime.now());
    String count(int? n) => n == null ? '–' : '$n';

    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: child,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.screen,
            bottom: AppSpacing.navClearance,
          ),
          children: [
            padded(
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Facilities desk',
                          style: AppText.meta.copyWith(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Semantics(
                          header: true,
                          child: Text(
                            'Hello, ${profile?.firstName ?? ''}',
                            style: AppText.greetingName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InitialsAvatar(
                    name: profile?.name ?? '',
                    onTap: () => context.go(Routes.staffProfile),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            padded(
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: count(stats?.newToday),
                          label: 'New today',
                          tone: StatTileTone.plum,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.listGap),
                      Expanded(
                        child: StatTile(
                          value: count(stats?.inProgress),
                          label: 'In progress',
                          tone: StatTileTone.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.listGap),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: count(stats?.underReview),
                          label: 'Under review',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.listGap),
                      Expanded(
                        child: StatTile(
                          value: count(stats?.resolvedThisWeek),
                          label: 'Resolved this week',
                          valueColor: c.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            padded(const SectionHeader(title: 'Report queue')),
            const SizedBox(height: 14),
            padded(
              SegmentedToggle<StaffQueue>(
                semanticLabel: 'Report queue',
                options: [
                  for (final q in StaffQueue.values) SegmentOption(q, q.label),
                ],
                selected: _queue,
                onChanged: (q) => setState(() => _queue = q),
              ),
            ),
            const SizedBox(height: 18),
            padded(
              AsyncValueView(
                value: reports,
                onRetry: () => ref.invalidate(allReportsProvider),
                data: (all) {
                  final shown = staffQueue(
                    all,
                    queue: _queue,
                    uid: profile?.uid ?? '',
                  );
                  if (shown.isEmpty) {
                    return EmptyState(
                      title: switch (_queue) {
                        StaffQueue.fresh => 'No new reports',
                        StaffQueue.mine => 'Nothing assigned to you',
                        StaffQueue.all => 'No reports yet',
                      },
                      message: switch (_queue) {
                        StaffQueue.fresh =>
                          'Every report has been picked up. New ones show '
                              'up here as soon as students send them.',
                        StaffQueue.mine =>
                          'Reports you assign to yourself, or that others '
                              'assign to you, show up here until resolved.',
                        StaffQueue.all =>
                          'Nothing has been reported on campus yet.',
                      },
                    );
                  }
                  return QueueCardList(reports: shown);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
