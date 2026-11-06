import 'package:flutter/material.dart';

import '../models/report_enums.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'neu_surface.dart';

enum TimelineStepState { done, current, upcoming }

class TimelineStep {
  const TimelineStep({
    required this.title,
    required this.subtitle,
    required this.state,
    this.titleColor,
    this.note,
  });

  final String title;
  final String subtitle;
  final TimelineStepState state;

  /// Colour of the current step's title (its status colour).
  final Color? titleColor;

  /// Staff note shown as a small raised card under the step.
  final String? note;
}

/// Vertical progress steps inside a pressed panel. Done steps are filled pink
/// with a pink line, the current step is an amber dot with a ring, upcoming
/// steps are hollow.
class ProgressTimeline extends StatelessWidget {
  const ProgressTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      depth: NeuDepth.pressed,
      shadow: NeuShadow.small,
      radius: AppRadii.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepRow(step: steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = step.state == TimelineStepState.done;
    final current = step.state == TimelineStepState.current;

    final Widget dot = switch (step.state) {
      TimelineStepState.done => _circle(16, fill: c.pinkMark),
      TimelineStepState.current => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.amber, width: 2),
        ),
        alignment: Alignment.center,
        child: _circle(16, fill: c.amber),
      ),
      TimelineStepState.upcoming => _circle(16, border: c.track),
    };

    final stateWord = switch (step.state) {
      TimelineStepState.done => 'done',
      TimelineStepState.current => 'current step',
      TimelineStepState.upcoming => 'not yet',
    };

    return Semantics(
      label:
          '${step.title}, $stateWord. ${step.subtitle}'
          '${step.note == null ? '' : '. Note: ${step.note}'}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  SizedBox(
                    height: current ? 28 : 20,
                    child: Center(child: dot),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        constraints: const BoxConstraints(minHeight: 22),
                        color: done ? c.pinkMark : c.track,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: current ? 3 : 0,
                  bottom: isLast ? 0 : 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: AppText.bodyStrong.copyWith(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: current ? FontWeight.w800 : FontWeight.w700,
                        color: switch (step.state) {
                          TimelineStepState.current =>
                            step.titleColor ?? c.textPrimary,
                          TimelineStepState.done => c.textPrimary,
                          TimelineStepState.upcoming => c.textSecondary,
                        },
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.subtitle,
                      style: AppText.meta.copyWith(color: c.textSecondary),
                    ),
                    if (step.note != null) ...[
                      const SizedBox(height: 8),
                      NeuSurface(
                        radius: 16,
                        shadow: NeuShadow.small,
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          step.note!,
                          style: AppText.body.copyWith(
                            fontSize: 13,
                            height: 1.5,
                            color: c.textBody,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, {Color? fill, Color? border}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: fill,
      border: border == null ? null : Border.all(color: border, width: 2),
    ),
  );
}

/// Four-step strip on the "Report submitted" ticket card. The current step is
/// filled amber.
class StatusStepStrip extends StatelessWidget {
  const StatusStepStrip({super.key, required this.current});

  final ReportStatus current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Progress: ${current.label}, step ${current.index + 1} of 4',
      excludeSemantics: true,
      child: NeuSurface(
        depth: NeuDepth.pressed,
        shadow: NeuShadow.insetSmall,
        radius: 16,
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final s in ReportStatus.values) ...[
              if (s.index > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s == current ? c.amber : null,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      s.shortLabel,
                      style: AppText.meta.copyWith(
                        fontSize: 10.5,
                        fontWeight: s == current
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: s == current ? c.onAmber : c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
