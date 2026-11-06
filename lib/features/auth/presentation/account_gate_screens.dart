import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/neu_card.dart';
import '../../../core/widgets/page_layout.dart';
import '../application/auth_controllers.dart';
import '../application/auth_providers.dart';
import '../../../core/widgets/form_message.dart';

/// Shared layout for the screens between signing in and using the app: logo
/// tile, heading, explanation, optional detail card, buttons at the bottom.
/// Not in the design; built from the same parts as Sign in.
class _GateLayout extends StatelessWidget {
  const _GateLayout({
    required this.title,
    required this.message,
    this.details,
    required this.actions,
  });

  final String title;
  final String message;
  final Widget? details;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: ScrollWithFooter(
        gap: 24,
        content: [
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Align(alignment: Alignment.centerLeft, child: LogoTile()),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: AppText.onboardingHeadline),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: AppText.body.copyWith(
                  fontSize: 15,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
          ?details,
        ],
        footer: actions,
      ),
    );
  }
}

/// Shown after sign up until the email link is clicked. Checks by itself
/// every few seconds, so most people never need to press "I've verified".
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _pollEvery = Duration(seconds: 5);
  Timer? _poll;
  Timer? _tick;

  VerifyEmailController get _controller =>
      ref.read(verifyEmailControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Accounts older than 24 hours that never verified are removed here.
    Future.microtask(() async {
      final removed = await _controller.removeIfExpired();
      if (removed || !mounted) return;
      _poll = Timer.periodic(_pollEvery, (_) => _controller.check(quiet: true));
    });
    // Redraws the "Resend in 42s" countdown.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final verified = await _controller.check();
    if (!verified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Not verified yet. Open the link in the email, then try again.",
          ),
        ),
      );
    }
  }

  Future<void> _resend() async {
    await _controller.resend();
    if (mounted && !ref.read(verifyEmailControllerProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent. Check your inbox and spam.')),
      );
    }
  }

  /// Removes the unverified account and opens Create account. Removing it
  /// signs the person out, and the router then sends signed-out people to
  /// Sign in, so the router is grabbed first (this screen is gone by the
  /// time the deletion finishes) and sent on to Create account.
  Future<void> _useDifferentEmail() async {
    final router = GoRouter.of(context);
    await _controller.useDifferentEmail();
    if (ref.read(authRepositoryProvider).currentUser == null) {
      router.go(Routes.signUp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyEmailControllerProvider);
    final email = ref.watch(authUserProvider).value?.email ?? 'your email';
    final wait = _controller.resendWait.inSeconds;

    return _GateLayout(
      title: 'Check your email',
      message:
          'We sent a link to $email. Open it to confirm this is your inbox, '
          'then come back here. This page moves on by itself.',
      details: NeuCard(
        child: Text(
          "Can't find it? Look in your spam folder. Accounts that aren't "
          'verified within 24 hours are removed.',
          style: AppText.body.copyWith(
            fontSize: 13.5,
            color: context.colors.textBody,
          ),
        ),
      ),
      actions: [
        if (state.hasError) FormMessage(friendlyErrorMessage(state.error!)),
        PrimaryButton(
          label: "I've verified",
          loading: state.isLoading,
          onPressed: _check,
        ),
        SecondaryButton(
          label: wait > 0 ? 'Resend email in ${wait}s' : 'Resend email',
          onPressed: wait > 0 || state.isLoading ? null : _resend,
        ),
        Center(
          child: TextLinkButton(
            label: 'Use a different email',
            onPressed: state.isLoading ? null : _useDifferentEmail,
          ),
        ),
      ],
    );
  }
}

/// Staff wait here until the facilities office sets `approved: true`. The
/// profile is a live stream, so the page moves on by itself.
class AwaitingApprovalScreen extends ConsumerWidget {
  const AwaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profile = ref.watch(currentProfileProvider).value;
    final meta = AppText.meta.copyWith(color: c.textSecondary);

    return _GateLayout(
      title: 'Waiting for approval',
      message:
          'Thanks${profile == null ? '' : ', ${profile.firstName}'}. The '
          'facilities office checks every staff account before it can update '
          "reports. You'll get in as soon as they approve it.",
      details: profile == null
          ? null
          : NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STAFF ID',
                    style: AppText.categoryLabel.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(profile.staffId ?? '-', style: AppText.cardTitle),
                  const SizedBox(height: 12),
                  Text(profile.email, style: meta),
                ],
              ),
            ),
      actions: [
        SecondaryButton(
          label: 'Sign out',
          foreground: c.error,
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }
}

/// Signed in and verified, but there is no profile document (for example it
/// was deleted in the console). Rare; offers a way out.
class AccountProblemScreen extends ConsumerWidget {
  const AccountProblemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GateLayout(
      title: "We couldn't load your profile",
      message:
          'Your login works, but your profile is missing. Sign out and try '
          'again, or contact the facilities office if this keeps happening.',
      actions: [
        PrimaryButton(
          label: 'Sign out',
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }
}

/// Shown for a moment while Firebase restores the session on launch.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(label: 'Loading', child: const LogoTile()),
      ),
    );
  }
}
