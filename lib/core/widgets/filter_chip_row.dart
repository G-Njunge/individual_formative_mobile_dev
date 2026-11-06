import 'package:flutter/material.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'neu_surface.dart';

class ChipOption<T> {
  const ChipOption(this.value, this.label);

  final T value;
  final String label;
}

/// Horizontally scrolling filter chips. Unselected chips are raised; the
/// selected chip is pressed with bold amber text.
///
/// Place it outside the page's horizontal padding: it adds its own padding so
/// the chips line up with the page but can scroll to the screen edge, and so
/// their shadows are not clipped.
class FilterChipRow<T> extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.horizontalPadding = AppSpacing.screen,
  });

  final List<ChipOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 8,
        ),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final option = options[i];
          return _Chip(
            label: option.label,
            selected: option.value == selected,
            onTap: () => onSelected(option.value),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return NeuPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: '$label filter',
      // The visible chip is 40 tall; the 2 px above and below bring the
      // touch target to 44.
      builder: (context, pressed) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: NeuSurface(
          depth: selected || pressed ? NeuDepth.pressed : NeuDepth.raised,
          shadow: selected || pressed ? NeuShadow.insetSmall : NeuShadow.small,
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppText.link.copyWith(
                color: selected ? c.amberLight : c.textBody,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
