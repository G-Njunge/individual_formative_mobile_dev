import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_icons.dart';
import 'neu_surface.dart';

class NavItem {
  const NavItem({
    required this.icon,
    required this.label,
    this.isAction = false,
    this.showBadge = false,
  });

  final AppIcon icon;

  /// Read by screen readers; the bar shows icons only.
  final String label;

  /// The amber + button. It performs an action instead of being a tab.
  final bool isAction;

  /// Small amber dot (unread notifications).
  final bool showBadge;
}

/// Raised bar that floats 16 from the sides and 18 from the bottom. The
/// current tab's icon sits in a pressed square and turns amber.
///
/// Use it as `Scaffold.bottomNavigationBar` with `extendBody: true` so content
/// scrolls underneath, and leave [AppSpacing.navClearance] at the bottom of
/// scrolling content.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: 'Main navigation',
          child: NeuSurface(
            radius: AppRadii.navBar,
            shadow: NeuShadow.navBar,
            height: 72,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Center(
                      child: items[i].isAction
                          ? _ActionButton(item: items[i], onTap: () => onTap(i))
                          : _Tab(
                              item: items[i],
                              selected: i == currentIndex,
                              onTap: () => onTap(i),
                              colors: c,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final RipotiColors colors;

  @override
  Widget build(BuildContext context) {
    return NeuPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: item.showBadge ? '${item.label}, unread' : item.label,
      builder: (context, pressed) => NeuSurface(
        depth: selected || pressed ? NeuDepth.pressed : NeuDepth.flat,
        shadow: NeuShadow.insetSmall,
        radius: 16,
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AppIconView(
              item.icon,
              color: selected ? colors.amberLight : colors.textTertiary,
              strokeWidth: selected ? 2.2 : 2,
            ),
            if (item.showBadge)
              Positioned(
                top: 11,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.item, required this.onTap});

  final NavItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return NeuPressable(
      onTap: onTap,
      semanticLabel: item.label,
      builder: (context, pressed) => NeuSurface(
        depth: pressed ? NeuDepth.pressed : NeuDepth.raised,
        shadow: pressed ? NeuShadow.insetSmall : NeuShadow.small,
        color: c.amber,
        radius: 18,
        width: 54,
        height: 54,
        child: Center(
          child: AppIconView(
            item.icon,
            color: c.onAmber,
            size: 24,
            strokeWidth: 2.6,
          ),
        ),
      ),
    );
  }
}
