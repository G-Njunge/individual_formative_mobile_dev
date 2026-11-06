import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'neu_surface.dart';

/// Plum logo square plus the wordmark (onboarding header).
class LogoWordmark extends StatelessWidget {
  const LogoWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: AppConfig.appName,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.plum,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: c.onPlum.withValues(alpha: 0.22)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppConfig.appName,
            style: AppText.pageTitle.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}

/// Raised 64 px tile with a small plum square (sign in).
class LogoTile extends StatelessWidget {
  const LogoTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${AppConfig.appName} logo',
      excludeSemantics: true,
      child: NeuSurface(
        radius: 22,
        width: 64,
        height: 64,
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: context.colors.plum,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return (first + last).toUpperCase();
}

/// Round avatar with initials. Small: 52 px raised circle with amber
/// initials (header, goes to Profile). Large: amber circle inside a raised
/// ring (Profile).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.large = false,
    this.onTap,
  });

  final String name;
  final bool large;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final initials = initialsOf(name);
    final Widget avatar = large
        ? NeuSurface(
            radius: 39,
            width: 78,
            height: 78,
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.amber,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initials,
                  style: AppText.pageTitle.copyWith(
                    fontSize: 20,
                    color: c.onAmber,
                  ),
                ),
              ),
            ),
          )
        : NeuSurface(
            radius: 26,
            shadow: NeuShadow.medium,
            width: 52,
            height: 52,
            child: Center(
              child: Text(
                initials,
                style: AppText.buttonLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: c.amberLight,
                ),
              ),
            ),
          );

    if (onTap == null) {
      return Semantics(label: name, excludeSemantics: true, child: avatar);
    }
    return NeuPressable(
      onTap: onTap,
      semanticLabel: 'Your profile',
      builder: (context, _) => avatar,
    );
  }
}

/// Section heading with an optional amber action on the right
/// ("Recent reports" / "View all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppText.sectionHeading),
          ),
        ),
        if (actionLabel != null)
          TextLinkButton(label: actionLabel!, onPressed: onAction),
      ],
    );
  }
}
