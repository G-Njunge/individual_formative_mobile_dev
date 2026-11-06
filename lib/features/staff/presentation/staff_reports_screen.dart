import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/report_enums.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/filter_chip_row.dart';
import '../../../core/widgets/neu_text_field.dart';
import '../../reports/application/report_filters.dart';
import '../../reports/application/report_providers.dart';
import 'widgets/staff_widgets.dart';

/// Staff "All reports" tab: every report with search, status chips and
/// sort, opening "Review and update". Not in the design; built from the same
/// parts as the student's Browse screen.
class StaffReportsScreen extends ConsumerStatefulWidget {
  const StaffReportsScreen({super.key});

  @override
  ConsumerState<StaffReportsScreen> createState() => _StaffReportsScreenState();
}

class _StaffReportsScreenState extends ConsumerState<StaffReportsScreen> {
  static final _chips = [
    const ChipOption<ReportStatus?>(null, 'All'),
    for (final s in ReportStatus.values) ChipOption<ReportStatus?>(s, s.label),
  ];

  final _search = TextEditingController();
  ReportStatus? _status;
  ReportSort _sort = ReportSort.newest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final all = ref.watch(allReportsProvider);
    final results = all.whenData(
      (r) =>
          filterReports(r, query: _search.text, status: _status, sort: _sort),
    );
    final narrowed = _search.text.trim().isNotEmpty || _status != null;

    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: child,
    );

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
                child: const Text('All reports', style: AppText.screenTitle),
              ),
            ),
            const SizedBox(height: 22),
            padded(
              NeuSearchField(
                hint: 'Search by title or place',
                controller: _search,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 14),
            FilterChipRow<ReportStatus?>(
              options: _chips,
              selected: _status,
              onSelected: (s) => setState(() => _status = s),
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
                      label: _sort.label,
                      onPressed: () => setState(() => _sort = _sort.next),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            padded(
              AsyncValueView(
                value: results,
                onRetry: () => ref.invalidate(allReportsProvider),
                data: (reports) {
                  if (reports.isNotEmpty) {
                    return QueueCardList(reports: reports);
                  }
                  return narrowed
                      ? const EmptyState(
                          title: 'No matching reports',
                          message: 'Try a different search or another filter.',
                        )
                      : const EmptyState(
                          title: 'No reports yet',
                          message: 'Nothing has been reported on campus yet.',
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
