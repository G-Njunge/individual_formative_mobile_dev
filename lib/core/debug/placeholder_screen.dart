import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../router/routes.dart';
import '../theme/text_styles.dart';
import '../theme/theme_mode_provider.dart';
import '../theme/tokens.dart';
import '../widgets/app_icons.dart';
import '../widgets/async_states.dart';
import '../widgets/brand.dart';
import '../widgets/buttons.dart';
import '../widgets/neu_card.dart';
import '../widgets/neu_switch.dart';

/// Temporary stand-in for screens that arrive in later milestones. It shows
/// who is signed in, so the routing can be checked end to end, plus sign out
/// and the theme switch. Every use is replaced by Milestone 5.
class PlaceholderScreen extends ConsumerWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.milestone,
    this.showAccount = false,
    this.closable = false,
  });

  final String title;
  final int milestone;

  /// Show the account card with sign out (Profile tabs).
  final bool showAccount;

  /// Full-screen page with a close button (New report).
  final bool closable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profile = ref.watch(sessionProvider).profile;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            24,
            AppSpacing.screen,
            AppSpacing.navClearance,
          ),
          children: [
            Row(
              children: [
                if (closable) ...[
                  NeuIconButton(
                    icon: AppIcon.close,
                    semanticLabel: 'Close',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: AppText.screenTitle),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            EmptyState(
              title: 'Coming in Milestone $milestone',
              message:
                  'This page is part of a later milestone. Routing, sign-in '
                  'and the nav bar already work.',
            ),
            if (showAccount && profile != null) ...[
              const SizedBox(height: 22),
              NeuCard(
                child: Row(
                  children: [
                    InitialsAvatar(name: profile.name),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name, style: AppText.cardTitle),
                          Text(
                            profile.email,
                            style: AppText.meta.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          Text(
                            profile.role.label.toUpperCase(),
                            style: AppText.categoryLabel.copyWith(
                              color: c.amberLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              NeuCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Dark mode', style: AppText.bodyStrong),
                    ),
                    NeuSwitch(
                      value: isDark,
                      width: 54,
                      height: 32,
                      semanticLabel: 'Dark mode',
                      onChanged: (v) =>
                          ref.read(themeModeProvider.notifier).setDark(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (kDebugMode) ...[
                SecondaryButton(
                  label: 'Component gallery (debug)',
                  onPressed: () => context.push(Routes.gallery),
                ),
                const SizedBox(height: 16),
              ],
              SecondaryButton(
                label: 'Sign out',
                foreground: c.error,
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
