import 'package:flutter/material.dart';

import '../models/report_enums.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'neu_surface.dart';

/// Pressed pill with the status word in its status colour.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: NeuSurface(
        depth: NeuDepth.pressed,
        shadow: NeuShadow.insetTiny,
        radius: 14,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          widthFactor: 1,
          child: Text(
            status.label,
            style: AppText.pill.copyWith(color: status.color(c)),
          ),
        ),
      ),
    );
  }
}

/// Staff-side urgency pill: High filled pink, Medium filled amber, Low pressed.
class UrgencyPill extends StatelessWidget {
  const UrgencyPill(this.urgency, {super.key});

  final Urgency urgency;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (depth, fill, text) = switch (urgency) {
      Urgency.high => (NeuDepth.flat, c.pinkFill, c.onAmber),
      Urgency.medium => (NeuDepth.flat, c.amber, c.onAmber),
      Urgency.low => (NeuDepth.pressed, c.base, c.textBody),
    };
    return Semantics(
      label: '${urgency.label} urgency',
      excludeSemantics: true,
      child: NeuSurface(
        depth: depth,
        shadow: NeuShadow.insetTiny,
        color: fill,
        radius: 13,
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          widthFactor: 1,
          child: Text(
            urgency.label,
            style: AppText.pill.copyWith(fontSize: 11.5, color: text),
          ),
        ),
      ),
    );
  }
}
