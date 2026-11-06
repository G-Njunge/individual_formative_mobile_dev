import 'package:flutter/material.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'neu_surface.dart';

enum StatTileTone { neutral, plum, amber }

/// Big number plus a label. Neutral tiles are raised base with an optional
/// coloured number; plum and amber are the two highlighted staff tiles.
/// [compact] is the centred, smaller version on Profile.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.tone = StatTileTone.neutral,
    this.valueColor,
    this.compact = false,
  });

  final String value;
  final String label;
  final StatTileTone tone;

  /// Number colour for neutral tiles (amber for open, teal for resolved).
  final Color? valueColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fill, number, text) = switch (tone) {
      StatTileTone.plum => (c.plum, c.onPlum, c.onPlumMuted),
      StatTileTone.amber => (c.amber, c.onAmber, c.onAmber),
      StatTileTone.neutral => (
        c.base,
        valueColor ?? c.textPrimary,
        c.textSecondary,
      ),
    };

    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: NeuSurface(
        color: fill,
        radius: compact ? 22 : AppRadii.card,
        shadow: compact ? NeuShadow.button : NeuShadow.large,
        padding: compact
            ? const EdgeInsets.symmetric(vertical: 16, horizontal: 8)
            : const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppText.statNumber.copyWith(
                color: number,
                fontSize: compact ? 24 : 30,
                height: compact ? 1.3 : 1,
              ),
            ),
            SizedBox(height: compact ? 2 : 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.statLabel.copyWith(
                color: text,
                fontSize: compact ? 12 : 13,
                fontWeight: tone == StatTileTone.amber
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
