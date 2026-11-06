import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum NeuDepth {
  /// Lifted off the page: dark shadow bottom-right, light edge top-left.
  raised,

  /// Pushed into the page: the same two shadows drawn inside the shape.
  pressed,

  /// No shadow at all (used for unselected options inside a pressed track).
  flat,
}

/// The single building block of the neumorphic look. Every card, button,
/// input, chip and pill is a [NeuSurface], so the shadow recipe lives in one
/// place and screens never build shadows by hand.
///
/// Flutter's [BoxShadow] can only draw outside a shape, so the pressed depth
/// uses [_InsetShadowPainter] instead of a third-party package.
class NeuSurface extends StatelessWidget {
  const NeuSurface({
    super.key,
    this.depth = NeuDepth.raised,
    this.shadow,
    this.radius = AppRadii.card,
    this.color,
    this.shadowDarkColor,
    this.shadowLightColor,
    this.padding,
    this.width,
    this.height,
    this.border,
    this.clip = false,
    this.child,
  });

  final NeuDepth depth;

  /// Shadow size. Defaults to [NeuShadow.large] raised or
  /// [NeuShadow.insetMedium] pressed.
  final NeuShadow? shadow;
  final double radius;

  /// Fill colour. Defaults to the page base colour.
  final Color? color;

  /// Shadow colours for coloured surfaces (e.g. the plum switch track).
  /// Default to the theme's shadowDark and shadowLight.
  final Color? shadowDarkColor;
  final Color? shadowLightColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  /// Optional outline, e.g. the red error outline on inputs.
  final BoxBorder? border;

  /// Clip the child to the rounded shape (photos inside frames).
  final bool clip;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fill = color ?? c.base;
    final borderRadius = BorderRadius.circular(radius);

    Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    if (clip) {
      content = ClipRRect(borderRadius: borderRadius, child: content);
    }

    final Widget surface = switch (depth) {
      NeuDepth.raised => DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: borderRadius,
          boxShadow: raisedShadows(c, shadow ?? NeuShadow.large),
        ),
        child: content,
      ),
      NeuDepth.pressed => CustomPaint(
        painter: _InsetShadowPainter(
          color: fill,
          borderRadius: borderRadius,
          shadow: shadow ?? NeuShadow.insetMedium,
          dark: shadowDarkColor ?? c.shadowDark,
          light: shadowLightColor ?? c.shadowLight,
        ),
        child: content,
      ),
      NeuDepth.flat => DecoratedBox(
        decoration: BoxDecoration(color: fill, borderRadius: borderRadius),
        child: content,
      ),
    };

    final bordered = border == null
        ? surface
        : DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: border,
              borderRadius: borderRadius,
            ),
            child: surface,
          );

    if (width == null && height == null) return bordered;
    return SizedBox(width: width, height: height, child: bordered);
  }

  /// The raised recipe, also used directly by widgets that animate between
  /// raised and flat (e.g. the selected option in a segmented toggle).
  static List<BoxShadow> raisedShadows(RipotiColors c, NeuShadow s) => [
    BoxShadow(
      color: c.shadowDark,
      offset: Offset(s.offset, s.offset),
      blurRadius: s.blur,
    ),
    BoxShadow(
      color: c.shadowLight,
      offset: Offset(-s.offset, -s.offset),
      blurRadius: s.blur,
    ),
  ];
}

/// Draws an inner shadow the way CSS `box-shadow: inset` does: fill the shape,
/// clip to it, then paint a blurred "frame" around a copy of the shape shifted
/// by the offset. Only the part of the blur that falls inside the shape shows.
class _InsetShadowPainter extends CustomPainter {
  _InsetShadowPainter({
    required this.color,
    required this.borderRadius,
    required this.shadow,
    required this.dark,
    required this.light,
  });

  final Color color;
  final BorderRadius borderRadius;
  final NeuShadow shadow;
  final Color dark;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    canvas.drawRRect(rrect, Paint()..color = color);

    canvas.save();
    canvas.clipRRect(rrect);
    final o = shadow.offset;
    final sigma = Shadow.convertRadiusToSigma(shadow.blur);
    final outer = rect.inflate(shadow.blur * 2 + o);
    // Dark shadow sits top-left inside, light edge bottom-right inside.
    for (final (shadowColor, offset) in [
      (dark, Offset(o, o)),
      (light, Offset(-o, -o)),
    ]) {
      final frame = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(outer)
        ..addRRect(rrect.shift(offset));
      canvas.drawPath(
        frame,
        Paint()
          ..color = shadowColor
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetShadowPainter old) =>
      old.color != color ||
      old.borderRadius != borderRadius ||
      old.shadow != shadow ||
      old.dark != dark ||
      old.light != light;
}

/// Tracks whether the user's finger is down so tappable surfaces can switch
/// to the pressed depth while touched, and adds button semantics. Each
/// control is responsible for keeping its own touch target at least 44 px.
class NeuPressable extends StatefulWidget {
  const NeuPressable({
    super.key,
    required this.builder,
    this.onTap,
    this.semanticLabel,
    this.selected,
    this.toggled,
  });

  final Widget Function(BuildContext context, bool pressed) builder;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool? selected;
  final bool? toggled;

  @override
  State<NeuPressable> createState() => _NeuPressableState();
}

class _NeuPressableState extends State<NeuPressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: widget.builder(context, _pressed),
      ),
    );
  }
}
