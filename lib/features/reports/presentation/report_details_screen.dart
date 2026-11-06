import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/report_enums.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/neu_card.dart';
import '../../../core/widgets/neu_surface.dart';
import '../../../core/widgets/pills.dart';
import '../../../core/widgets/progress_timeline.dart';
import '../application/report_filters.dart';
import '../application/report_providers.dart';
import '../data/report.dart';

/// Everything about one report: photos, details, how many people back it,
/// and the live progress timeline.
class ReportDetailsScreen extends ConsumerWidget {
  const ReportDetailsScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider(reportId));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.screen,
            AppSpacing.screen,
            40,
          ),
          children: [
            Row(
              children: [
                NeuIconButton(
                  icon: AppIcon.back,
                  semanticLabel: 'Back',
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.home),
                ),
                const Spacer(),
                if (report.value case final r?)
                  Text(
                    r.ticketLabel,
                    style: AppText.categoryLabel.copyWith(
                      fontSize: 13,
                      color: context.colors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            AsyncValueView(
              value: report,
              onRetry: () => ref.invalidate(reportProvider(reportId)),
              loading: const LoadingState(itemCount: 2, itemHeight: 180),
              data: (r) => r == null
                  ? const EmptyState(
                      title: 'Report not found',
                      message:
                          'It may have been removed, or the link is wrong.',
                    )
                  : _ReportBody(report: r),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isMine = ref.watch(
      isMyReportProvider((id: report.id, reporterId: report.reporterId)),
    );
    final timeline = ref.watch(reportTimelineProvider(report.id));
    final created = report.createdAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (report.photoCount > 0) ...[
          _PhotoFrame(reportId: report.id, count: report.photoCount),
          const SizedBox(height: AppSpacing.section),
        ],
        Row(
          children: [
            Text(
              report.category.label.toUpperCase(),
              style: AppText.categoryLabel.copyWith(color: c.textSecondary),
            ),
            const SizedBox(width: 10),
            StatusPill(report.status),
          ],
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(
            report.title,
            style: AppText.pageTitle.copyWith(fontSize: 23, height: 1.25),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          [
            report.location,
            if (created != null) TimeFormat.dayAndTime(created),
            '${report.urgency.label} urgency',
          ].join(' · '),
          style: AppText.meta.copyWith(fontSize: 13, color: c.textSecondary),
        ),
        const SizedBox(height: 14),
        Text(
          report.description,
          style: AppText.body.copyWith(height: 1.6, color: c.textBody),
        ),
        if (isMine && report.anonymous) ...[
          const SizedBox(height: 10),
          Text(
            'Sent anonymously. Staff can’t see your name.',
            style: AppText.meta.copyWith(color: c.textSecondary),
          ),
        ],
        if (report.duplicateOf case final dup?) ...[
          const SizedBox(height: 14),
          NeuCard(
            onTap: () => context.push(Routes.reportDetails(dup.id)),
            semanticLabel:
                'Closed as a duplicate of ticket ${dup.ticketNumber}. Open it',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Closed as a duplicate of #${dup.ticketNumber}. Follow '
                    'that ticket for updates.',
                    style: AppText.body.copyWith(
                      fontSize: 14,
                      color: c.textBody,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AppIconView(AppIcon.chevronRight, color: c.amberLight),
              ],
            ),
          ),
        ],
        if (report.hasAfterPhoto) ...[
          const SizedBox(height: AppSpacing.section),
          _AfterPhoto(reportId: report.id),
        ],
        const SizedBox(height: AppSpacing.section),
        _BackersCard(count: report.meTooCount),
        const SizedBox(height: AppSpacing.section),
        Semantics(
          header: true,
          child: Text(
            'Progress',
            style: AppText.sectionHeading.copyWith(fontSize: 17),
          ),
        ),
        const SizedBox(height: AppSpacing.listGap),
        AsyncValueView(
          value: timeline,
          onRetry: () => ref.invalidate(reportUpdatesProvider(report.id)),
          loading: const LoadingState(itemCount: 1, itemHeight: 220),
          data: (entries) => ProgressTimeline(
            steps: [
              for (final e in entries) _toStep(context, e, isMine: isMine),
            ],
          ),
        ),
      ],
    );
  }

  TimelineStep _toStep(
    BuildContext context,
    TimelineEntry e, {
    required bool isMine,
  }) {
    final c = context.colors;
    final time = e.time;
    final subtitle = switch (e.state) {
      TimelineState.upcoming => switch (e.status) {
        ReportStatus.underReview => 'Waiting for campus staff',
        ReportStatus.inProgress => 'Not started yet',
        ReportStatus.resolved =>
          isMine ? 'You will be asked to confirm the fix' : 'Not fixed yet',
        ReportStatus.submitted => '',
      },
      _ => [if (time != null) TimeFormat.dayAndTime(time), ?e.by].join(' · '),
    };
    return TimelineStep(
      title: e.status.label,
      subtitle: subtitle.isEmpty ? 'Done' : subtitle,
      state: switch (e.state) {
        TimelineState.done => TimelineStepState.done,
        TimelineState.current => TimelineStepState.current,
        TimelineState.upcoming => TimelineStepState.upcoming,
      },
      titleColor: e.status.color(c),
      note: e.note,
    );
  }
}

/// The photo staff took of the fix.
class _AfterPhoto extends ConsumerWidget {
  const _AfterPhoto({required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(reportAfterPhotoProvider(reportId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'After the fix',
            style: AppText.sectionHeading.copyWith(fontSize: 17),
          ),
        ),
        const SizedBox(height: AppSpacing.listGap),
        AsyncValueView(
          value: photo,
          onRetry: () => ref.invalidate(reportAfterPhotoProvider(reportId)),
          loading: const LoadingState(itemCount: 1, itemHeight: 200),
          data: (bytes) => bytes == null
              ? const SizedBox.shrink()
              : ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      semanticLabel: 'Photo of the fix',
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// "12 students also see this issue". The Me too button that adds to the
/// count arrives in Milestone 5.
class _BackersCard extends StatelessWidget {
  const _BackersCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (headline, detail) = switch (count) {
      0 => ('No one else yet', 'has said they see this issue'),
      1 => ('1 student', 'also sees this issue'),
      _ => ('$count students', 'also see this issue'),
    };
    return NeuCard(
      semanticLabel: '$headline $detail',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: AppText.bodyStrong.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(detail, style: AppText.meta.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}

/// The report's photos in a raised frame. Several photos swipe, with dots
/// showing which one is open.
class _PhotoFrame extends ConsumerStatefulWidget {
  const _PhotoFrame({required this.reportId, required this.count});

  final String reportId;
  final int count;

  @override
  ConsumerState<_PhotoFrame> createState() => _PhotoFrameState();
}

class _PhotoFrameState extends ConsumerState<_PhotoFrame> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final photos = ref.watch(reportPhotosProvider(widget.reportId));

    Widget frame(Widget child) => NeuSurface(
      radius: 30,
      shadow: const NeuShadow(10, 22),
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(height: 220, width: double.infinity, child: child),
      ),
    );

    return photos.when(
      skipLoadingOnReload: true,
      loading: () => frame(
        NeuSurface(
          depth: NeuDepth.pressed,
          radius: 22,
          child: Center(
            child: Semantics(
              label: 'Loading photo',
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: c.amberLight,
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => ErrorState(
        title: "Photos didn't load",
        message: friendlyErrorMessage(e),
        onRetry: () => ref.invalidate(reportPhotosProvider(widget.reportId)),
      ),
      data: (List<Uint8List> list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            frame(
              PageView.builder(
                itemCount: list.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Image.memory(
                  list[i],
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  semanticLabel:
                      'Photo ${i + 1} of ${list.length} attached to the '
                      'report',
                ),
              ),
            ),
            if (list.length > 1) ...[
              const SizedBox(height: 14),
              ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < list.length; i++)
                      AnimatedContainer(
                        duration: AppDurations.medium,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? c.amber : c.track,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
