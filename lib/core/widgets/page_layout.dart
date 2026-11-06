import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A page whose content scrolls, with [footer] pushed to the bottom when there
/// is room (sign in, verify email). When the keyboard opens or the screen is
/// short, everything scrolls together instead of overflowing.
class ScrollWithFooter extends StatelessWidget {
  const ScrollWithFooter({
    super.key,
    required this.content,
    this.footer = const [],
    this.padding = const EdgeInsets.fromLTRB(24, 22, 24, 28),
    this.gap = 20,
  });

  final List<Widget> content;
  final List<Widget> footer;
  final EdgeInsets padding;

  /// Space between each item.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: padding,
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._spaced(content),
                  const Spacer(),
                  if (footer.isNotEmpty) SizedBox(height: gap),
                  ..._spaced(footer),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _spaced(List<Widget> items) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) SizedBox(height: gap),
      items[i],
    ],
  ];
}

/// Title row with a back or close button, used at the top of inner pages.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.leading,
    this.title,
    this.overline,
    this.trailing,
  });

  final Widget leading;
  final String? title;

  /// Small uppercase label above the title ("TICKET #1042").
  final String? overline;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading,
        if (title != null || overline != null) const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (overline != null)
                Text(
                  overline!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: context.colors.textSecondary,
                  ),
                ),
              if (title != null)
                Semantics(
                  header: true,
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
