import 'package:flutter/material.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'app_icons.dart';
import 'neu_surface.dart';

enum ButtonSize {
  /// 58 tall, radius 20, 16/700. Full-width calls to action.
  large(58, AppRadii.button, AppText.buttonLarge),

  /// 52 tall, radius 20, 14/700. Secondary actions under a primary one.
  medium(52, AppRadii.button, AppText.buttonSmall),

  /// 42 to 46 tall, radius 14, 13 to 14/700. Buttons inside cards.
  small(44, AppRadii.smallButton, AppText.buttonSmall),

  /// Fully rounded 44 tall pill, 13/700 ("Skip").
  pill(44, 22, AppText.link);

  const ButtonSize(this.height, this.radius, this.textStyle);

  final double height;
  final double radius;
  final TextStyle textStyle;
}

/// Amber call to action. Shows a spinner while [loading] and fades out when
/// disabled ([onPressed] is null).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.size = ButtonSize.large,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final ButtonSize size;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _NeuButton(
      label: label,
      onPressed: loading ? null : onPressed,
      dimmed: onPressed == null && !loading,
      loading: loading,
      size: size,
      expand: expand,
      fill: c.amber,
      foreground: c.onAmber,
    );
  }
}

/// Raised base-coloured button. [foreground] overrides the text colour
/// (e.g. the error colour for "Sign out").
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.size = ButtonSize.medium,
    this.expand = true,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final ButtonSize size;
  final bool expand;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _NeuButton(
      label: label,
      onPressed: loading ? null : onPressed,
      dimmed: onPressed == null && !loading,
      loading: loading,
      size: size,
      expand: expand,
      fill: c.base,
      foreground: foreground ?? c.textPrimary,
    );
  }
}

class _NeuButton extends StatelessWidget {
  const _NeuButton({
    required this.label,
    required this.onPressed,
    required this.dimmed,
    required this.loading,
    required this.size,
    required this.expand,
    required this.fill,
    required this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool dimmed;
  final bool loading;
  final ButtonSize size;
  final bool expand;
  final Color fill;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final shadow = switch (size) {
      ButtonSize.small => NeuShadow.small,
      ButtonSize.pill => NeuShadow.medium,
      _ => NeuShadow.button,
    };
    return Semantics(
      liveRegion: loading,
      child: NeuPressable(
        onTap: onPressed,
        semanticLabel: loading ? '$label, loading' : label,
        builder: (context, pressed) => AnimatedOpacity(
          duration: AppDurations.fast,
          opacity: dimmed ? 0.5 : 1,
          child: NeuSurface(
            depth: pressed ? NeuDepth.pressed : NeuDepth.raised,
            shadow: pressed ? NeuShadow.insetSmall : shadow,
            radius: size.radius,
            color: fill,
            width: expand ? double.infinity : null,
            height: size.height,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              widthFactor: 1,
              child: loading
                  ? SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: foreground,
                      ),
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: size.textStyle.copyWith(color: foreground),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 46 × 46 raised square for back and close.
class NeuIconButton extends StatelessWidget {
  const NeuIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final AppIcon icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return NeuPressable(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => NeuSurface(
        depth: pressed ? NeuDepth.pressed : NeuDepth.raised,
        shadow: pressed ? NeuShadow.insetSmall : NeuShadow.medium,
        radius: AppRadii.iconButton,
        width: 46,
        height: 46,
        child: Center(
          child: AppIconView(
            icon,
            color: c.textPrimary,
            size: icon == AppIcon.close ? 18 : 20,
            strokeWidth: icon == AppIcon.close ? 2.4 : 2.2,
          ),
        ),
      ),
    );
  }
}

/// Amber text button ("View all", "Forgot password?", "Change").
/// Keeps a 44 px tall touch target even though the text is small.
class TextLinkButton extends StatelessWidget {
  const TextLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppText.link,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final TextStyle style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              style: style.copyWith(color: color ?? context.colors.amberLight),
            ),
          ),
        ),
      ),
    );
  }
}
