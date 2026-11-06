import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'neu_surface.dart';

/// Raised card, radius 24, padding 18. When [onTap] is set it sinks into the
/// page (pressed depth) while touched.
class NeuCard extends StatelessWidget {
  const NeuCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.radius = AppRadii.card,
    this.color,
    this.shadow = NeuShadow.large,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Read by screen readers instead of the card's text, when given.
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final NeuShadow shadow;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return NeuSurface(
        radius: radius,
        color: color,
        shadow: shadow,
        padding: padding,
        child: child,
      );
    }
    return NeuPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => NeuSurface(
        depth: pressed ? NeuDepth.pressed : NeuDepth.raised,
        shadow: pressed ? NeuShadow.insetMedium : shadow,
        radius: radius,
        color: color,
        padding: padding,
        child: child,
      ),
    );
  }
}
