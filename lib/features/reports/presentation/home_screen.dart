import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/report_enums.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/filter_chip_row.dart';
import '../../../core/widgets/neu_text_field.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../auth/application/auth_providers.dart';
import '../application/report_filters.dart';
import '../application/report_providers.dart';
import 'widgets/report_widgets.dart';

/// Student home: greeting, search, "Spotted a problem?", the student's own
/// open and resolved counts, and their most recent reports.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// How many recent reports Home lists before "View all".
  static const recentLimit = 5;

  static const _chips = [
    ChipOption<ReportStatus?>(null, 'All'),
    ChipOption<ReportStatus?>(ReportStatus.submitted, 'Submitted'),
    ChipOption<ReportStatus?>(ReportStatus.inProgress, 'In progress'),
    ChipOption<ReportStatus?>(ReportStatus.resolved, 'Resolved'),
  ];

  final _search = TextEditingController();
  ReportStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String greeting(DateTime now) => switch (now.hour) {
    < 12 => 'Good morning,',
    < 17 => 'Good afternoon,',
    _ => 'Good evening,',
  };

  void _openBrowse(BrowseScope scope, {String query = ''}) {
    ref
        .read(browseFiltersProvider.notifier)
        .open(scope: scope, query: query.trim());
    context.go(Routes.reports);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profile = ref.watch(sessionProvider).profile;
    final mine = ref.watch(myReportsProvider);
    final stats = mine.whenData(ReportStats.of).value;

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
                          greeting(DateTime.now()),
                          style: AppText.meta.copyWith(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Semantics(
                          header: true,
                          child: Text(
                            profile?.firstName ?? '',
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
                    onTap: () => context.go(Routes.profile),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            padded(
              NeuSearchField(
                hint: 'Search reports or places',
                controller: _search,
                onSubmitted: (q) {
                  _openBrowse(BrowseScope.all, query: q);
                  _search.clear();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            padded(
              SpottedProblemCard(
                onReport: () => context.push(Routes.newReport),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            padded(
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: stats == null ? '–' : '${stats.open}',
                      label: 'Open reports',
                      valueColor: c.amberLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.listGap),
                  Expanded(
                    child: StatTile(
                      value: stats == null ? '–' : '${stats.resolved}',
                      label: 'Resolved',
                      valueColor: c.teal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            padded(
              SectionHeader(
                title: 'Recent reports',
                actionLabel: 'View all',
                onAction: () => _openBrowse(BrowseScope.mine),
              ),
            ),
            const SizedBox(height: 8),
            FilterChipRow<ReportStatus?>(
              options: _chips,
              selected: _status,
              onSelected: (s) => setState(() => _status = s),
            ),
            const SizedBox(height: 8),
            padded(
              AsyncValueView(
                value: mine,
                onRetry: () => retryMyReports(ref),
                data: (reports) {
                  if (reports.isEmpty) {
                    return EmptyState(
                      title: 'No reports yet',
                      message:
                          'When you report something on campus, you can '
                          'follow it here until it is fixed.',
                      actionLabel: 'Report an issue',
                      onAction: () => context.push(Routes.newReport),
                    );
                  }
                  final shown = filterReports(reports, status: _status);
                  if (shown.isEmpty) {
                    return EmptyState(
                      title: 'Nothing ${_status!.label.toLowerCase()}',
                      message:
                          'None of your reports are '
                          '${_status!.label.toLowerCase()} right now.',
                    );
                  }
                  return ReportCardList(
                    reports: shown.take(recentLimit).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
