import 'package:flutter/material.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'neu_surface.dart';

/// A raised text button that becomes pressed, with coloured bold text, when
/// selected. Used for the category grid (New report) and the status radio
/// group (staff update).
class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
    this.height = 50,
    this.radius = 16,
    this.fontSize = 13.5,
    this.isRadio = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Text colour when selected. Defaults to amberLight.
  final Color? selectedColor;
  final double height;
  final double radius;
  final double fontSize;

  /// Announce as a radio button (one of a group) instead of a toggle.
  final bool isRadio;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: isRadio,
      checked: isRadio ? selected : null,
      child: NeuPressable(
        onTap: onTap,
        selected: selected,
        semanticLabel: label,
        builder: (context, pressed) => NeuSurface(
          depth: selected || pressed ? NeuDepth.pressed : NeuDepth.raised,
          shadow: selected || pressed
              ? NeuShadow.insetMedium
              : NeuShadow.medium,
          radius: radius,
          height: height,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.buttonSmall.copyWith(
                fontSize: fontSize,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                color: selected
                    ? selectedColor ?? c.amberLight
                    : isRadio
                    ? c.textBody
                    : c.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays children out in rows of [columns] equal-width cells. Unlike
/// [GridView] the row height follows the content, which suits neumorphic
/// tiles whose height is fixed by the design rather than an aspect ratio.
class GridRows extends StatelessWidget {
  const GridRows({
    super.key,
    required this.columns,
    required this.children,
    this.spacing = 14,
    this.runSpacing,
  });

  final int columns;
  final List<Widget> children;
  final double spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      if (start > 0) rows.add(SizedBox(height: runSpacing ?? spacing));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              Expanded(
                child: start + i < children.length
                    ? children[start + i]
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
