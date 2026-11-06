import 'package:flutter/material.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'neu_surface.dart';

class SegmentOption<T> {
  const SegmentOption(this.value, this.label);

  final T value;
  final String label;
}

/// Pressed track holding 2 or 3 options. The selected option rises out of the
/// track as a raised pill with amber text. With [filledSelection] (urgency)
/// the selected pill is filled amber instead.
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.filledSelection = false,
    this.optionHeight = 46,
    this.semanticLabel,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool filledSelection;
  final double optionHeight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: semanticLabel,
      container: true,
      child: NeuSurface(
        depth: NeuDepth.pressed,
        radius: AppRadii.button,
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _option(c, options[i])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _option(RipotiColors c, SegmentOption<T> option) {
    final on = option.value == selected;
    final Color fill;
    final Color text;
    if (on && filledSelection) {
      fill = c.amber;
      text = c.onAmber;
    } else if (on) {
      fill = c.base;
      text = c.amberLight;
    } else {
      fill = c.base.withValues(alpha: 0);
      text = filledSelection ? c.textBody : c.textSecondary;
    }

    return Semantics(
      button: true,
      selected: on,
      label: option.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(option.value),
        child: AnimatedContainer(
          duration: AppDurations.medium,
          curve: Curves.easeOut,
          height: optionHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(
              filledSelection ? AppRadii.smallButton : AppRadii.tab,
            ),
            // Same shadows either way, faded out when unselected, so the
            // selected pill appears to rise out of the track.
            boxShadow: [
              for (final s in NeuSurface.raisedShadows(
                c,
                filledSelection ? NeuShadow.insetSmall : NeuShadow.insetMedium,
              ))
                on ? s : s.copyWith(color: s.color.withValues(alpha: 0)),
            ],
          ),
          child: Text(
            option.label,
            style: AppText.buttonSmall.copyWith(
              color: text,
              fontWeight: on ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
