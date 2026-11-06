import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/report_enums.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/filter_chip_row.dart';
import '../../../core/widgets/neu_text_field.dart';
import '../../../core/widgets/segmented_toggle.dart';
import '../application/report_providers.dart';
import 'widgets/report_widgets.dart';

/// "Campus reports": every report, or only the student's own, with search,
/// status chips and sort. All filtering happens in [browseResultsProvider].
class BrowseReportsScreen extends ConsumerStatefulWidget {
  const BrowseReportsScreen({super.key});

  @override
  ConsumerState<BrowseReportsScreen> createState() =>
      _BrowseReportsScreenState();
}

class _BrowseReportsScreenState extends ConsumerState<BrowseReportsScreen> {
  static final _chips = [
    const ChipOption<ReportStatus?>(null, 'All'),
    for (final s in ReportStatus.values) ChipOption<ReportStatus?>(s, s.label),
  ];

  late final _search = TextEditingController(
    text: ref.read(browseFiltersProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filters = ref.watch(browseFiltersProvider);
    final results = ref.watch(browseResultsProvider);
    final controller = ref.read(browseFiltersProvider.notifier);

    // Home can open this tab with a search already typed.
    ref.listen(browseFiltersProvider.select((f) => f.query), (_, query) {
      if (_search.text != query) _search.text = query;
    });

    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: child,
    );

    final narrowed = filters.query.trim().isNotEmpty || filters.status != null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.section,
            bottom: AppSpacing.navClearance,
          ),
          children: [
            padded(
              Semantics(
                header: true,
                child: const Text('Campus reports', style: AppText.screenTitle),
              ),
            ),
            const SizedBox(height: 22),
            padded(
              SegmentedToggle<BrowseScope>(
                semanticLabel: 'Which reports',
                options: const [
                  SegmentOption(BrowseScope.all, 'All reports'),
                  SegmentOption(BrowseScope.mine, 'My reports'),
                ],
                selected: filters.scope,
                onChanged: controller.setScope,
              ),
            ),
            const SizedBox(height: 22),
            padded(
              NeuSearchField(
                hint: 'Search by title or place',
                controller: _search,
                onChanged: controller.setQuery,
              ),
            ),
            const SizedBox(height: 14),
            FilterChipRow<ReportStatus?>(
              options: _chips,
              selected: filters.status,
              onSelected: controller.setStatus,
            ),
            const SizedBox(height: 8),
            padded(
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(switch (results.value?.length) {
                        null => '',
                        1 => '1 report',
                        final n => '$n reports',
                      }, style: AppText.link.copyWith(color: c.textSecondary)),
                    ),
                  ),
                  Semantics(
                    hint: 'Changes the order',
                    child: TextLinkButton(
                      label: filters.sort.label,
                      onPressed: controller.cycleSort,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            padded(
              AsyncValueView(
                value: results,
                onRetry: () => filters.scope == BrowseScope.all
                    ? ref.invalidate(allReportsProvider)
                    : retryMyReports(ref),
                data: (reports) {
                  if (reports.isNotEmpty) {
                    return ReportCardList(reports: reports, showMeToo: true);
                  }
                  if (narrowed) {
                    return const EmptyState(
                      title: 'No matching reports',
                      message: 'Try a different search or another filter.',
                    );
                  }
                  return filters.scope == BrowseScope.mine
                      ? EmptyState(
                          title: "You haven't reported anything yet",
                          message:
                              'Spotted something broken? It only takes a '
                              'minute.',
                          actionLabel: 'Report an issue',
                          onAction: () => context.push(Routes.newReport),
                        )
                      : const EmptyState(
                          title: 'No reports yet',
                          message:
                              'Nothing has been reported on campus yet. '
                              'Reports from everyone will show up here.',
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
