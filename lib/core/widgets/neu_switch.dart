import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'neu_surface.dart';

/// Pressed track with a raised knob. ON turns the track plum.
class NeuSwitch extends StatelessWidget {
  const NeuSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.width = 56,
    this.height = 34,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final knob = height - 8;
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        // Pads the hit area to at least 44 px tall.
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: ((44 - height) / 2).clamp(0, 22),
          ),
          child: Opacity(
            opacity: onChanged == null ? 0.5 : 1,
            child: _Track(
              on: value,
              width: width,
              height: height,
              colors: c,
              child: AnimatedAlign(
                duration: AppDurations.fast,
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: knob,
                  height: knob,
                  decoration: BoxDecoration(
                    color: c.base,
                    shape: BoxShape.circle,
                    boxShadow: NeuSurface.raisedShadows(c, NeuShadow.insetTiny),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.on,
    required this.width,
    required this.height,
    required this.colors,
    required this.child,
  });

  final bool on;
  final double width;
  final double height;
  final RipotiColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // ON: plum track with a darker plum inner shadow, as in the design.
    return NeuSurface(
      depth: NeuDepth.pressed,
      shadow: NeuShadow.insetSmall,
      color: on ? colors.plum : null,
      shadowDarkColor: on ? colors.plumTrackShadow : null,
      shadowLightColor: on ? colors.plum : null,
      radius: height / 2,
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      child: child,
    );
  }
}
