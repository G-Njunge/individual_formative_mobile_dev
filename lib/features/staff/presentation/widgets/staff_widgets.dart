import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/report_card.dart';
import '../../../reports/data/report.dart';
import '../../../reports/presentation/widgets/report_widgets.dart';

/// A column of staff queue cards that open "Review and update".
class QueueCardList extends StatelessWidget {
  const QueueCardList({super.key, required this.reports});

  final List<Report> reports;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < reports.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.listGap),
          QueueReportCard(
            key: ValueKey(reports[i].id),
            category: reports[i].category,
            title: reports[i].title,
            place: reports[i].location,
            timeLabel: reportTimeLabel(reports[i]),
            status: reports[i].status,
            urgency: reports[i].urgency,
            meTooCount: reports[i].meTooCount,
            onTap: () => context.push(Routes.staffReview(reports[i].id)),
          ),
        ],
      ],
    );
  }
}
