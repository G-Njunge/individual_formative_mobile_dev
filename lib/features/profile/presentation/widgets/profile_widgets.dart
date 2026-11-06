import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/neu_card.dart';
import '../../../../core/widgets/neu_switch.dart';
import '../../../auth/application/auth_providers.dart';

/// Large amber avatar, name, email and the role in amber capitals.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.roleLabel,
  });

  final String name;
  final String email;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        InitialsAvatar(name: name, large: true),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppText.pageTitle.copyWith(fontSize: 21),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: AppText.meta.copyWith(
                  fontSize: 13.5,
                  color: c.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                roleLabel.toUpperCase(),
                style: AppText.categoryLabel.copyWith(color: c.amberLight),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A raised card of rows separated by dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return NeuCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One row: a label, then a chevron (opens a page) or a [trailing] widget.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.onTap,
    this.trailing,
    this.detail,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Small text under the label.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.bodyStrong.copyWith(fontSize: 15)),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    style: AppText.meta.copyWith(color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing ??
              AppIconView(
                AppIcon.chevronRight,
                color: c.textSecondary,
                size: 18,
              ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

/// "Dark mode" with its switch.
class DarkModeRow extends ConsumerWidget {
  const DarkModeRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return SettingsRow(
      label: 'Dark mode',
      trailing: NeuSwitch(
        value: dark,
        semanticLabel: 'Dark mode',
        onChanged: (on) => ref.read(themeModeProvider.notifier).setDark(on),
      ),
    );
  }
}

/// Raised "Sign out" in the error colour.
class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SecondaryButton(
      label: 'Sign out',
      size: ButtonSize.large,
      foreground: context.colors.error,
      onPressed: () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}

/// Back button plus title, for the pages opened from Profile.
class SubPageHeader extends StatelessWidget {
  const SubPageHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NeuIconButton(
          icon: AppIcon.back,
          semanticLabel: 'Back',
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppText.pageTitle),
          ),
        ),
      ],
    );
  }
}
