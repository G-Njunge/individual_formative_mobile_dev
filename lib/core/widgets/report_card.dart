import 'package:flutter/material.dart';

import '../models/report_enums.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'neu_card.dart';
import 'pills.dart';

/// Student-side report card: category, title, "place · time" and a status
/// pill. Browse passes [meTooCount] to show "N me too" in the top-right.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.category,
    required this.title,
    required this.place,
    required this.timeLabel,
    required this.status,
    this.meTooCount,
    this.onTap,
  });

  final ReportCategory category;
  final String title;
  final String place;
  final String timeLabel;
  final ReportStatus status;
  final int? meTooCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final meta = AppText.meta.copyWith(color: c.textSecondary);
    return NeuCard(
      onTap: onTap,
      semanticLabel:
          '${category.label} report: $title. $place, $timeLabel. '
          'Status ${status.label}'
          '${meTooCount == null ? '' : '. $meTooCount me too'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.label.toUpperCase(),
                  style: AppText.categoryLabel.copyWith(color: c.textSecondary),
                ),
              ),
              if (meTooCount != null)
                Text(
                  '$meTooCount me too',
                  style: AppText.pill.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.cardGap),
          Text(title, style: AppText.cardTitle),
          const SizedBox(height: AppSpacing.cardGap),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$place · $timeLabel',
                  style: meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(status),
            ],
          ),
        ],
      ),
    );
  }
}

/// Staff queue card: "CATEGORY · time" with an urgency pill, the title, then
/// "place · status · N me too".
class QueueReportCard extends StatelessWidget {
  const QueueReportCard({
    super.key,
    required this.category,
    required this.title,
    required this.place,
    required this.timeLabel,
    required this.status,
    required this.urgency,
    required this.meTooCount,
    this.onTap,
  });

  final ReportCategory category;
  final String title;
  final String place;
  final String timeLabel;
  final ReportStatus status;
  final Urgency urgency;
  final int meTooCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return NeuCard(
      onTap: onTap,
      semanticLabel:
          '${urgency.label} urgency ${category.label} report: $title. '
          '$place, ${status.label}, $meTooCount me too, $timeLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${category.label.toUpperCase()} · $timeLabel',
                  style: AppText.categoryLabel.copyWith(color: c.textSecondary),
                ),
              ),
              UrgencyPill(urgency),
            ],
          ),
          const SizedBox(height: AppSpacing.cardGap),
          Text(title, style: AppText.cardTitle),
          const SizedBox(height: AppSpacing.cardGap),
          Text(
            '$place · ${status.label} · $meTooCount me too',
            style: AppText.meta.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
