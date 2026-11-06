import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/neu_surface.dart';
import '../application/onboarding_provider.dart';

class _Slide {
  const _Slide(this.asset, this.line1, this.line2, this.body, this.imageLabel);

  final String asset;
  final String line1;
  final String line2;
  final String body;
  final String imageLabel;
}

const _slides = [
  _Slide(
    'assets/illustrations/onboarding_1_see_it.svg',
    'Spot something',
    'broken on campus?',
    'Leaking taps, power cuts, broken chairs, unsafe paths. If it gets in '
        'the way of campus life, report it.',
    'A student points at a broken tap spraying water onto the floor',
  ),
  _Slide(
    'assets/illustrations/onboarding_2_snap_it.svg',
    'Snap it.',
    'Report it.',
    'Take a photo, pick a category and add a short note. Your report '
        'reaches campus staff in seconds.',
    'The student photographs the broken tap with her phone',
  ),
  _Slide(
    'assets/illustrations/onboarding_3_fixed.svg',
    'Watch it',
    'get fixed.',
    'Follow every report from submitted to resolved, and get notified the '
        'moment something changes.',
    'A technician repairs the tap while the student gives a thumbs up',
  ),
];

/// First-launch carousel. Auto-advances every 4 seconds and loops; swiping or
/// tapping a dot changes slide and restarts the timer.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(AppDurations.onboardingInterval, (_) {
      _goTo((_page + 1) % _slides.length, restartTimer: false);
    });
  }

  void _goTo(int page, {bool restartTimer = true}) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      page,
      duration: AppDurations.slide,
      curve: Curves.easeOutCubic,
    );
    if (restartTimer) _restartTimer();
  }

  /// Leaving onboarding by any button counts as having seen it.
  void _leave(String route) {
    ref.read(onboardingSeenProvider.notifier).markSeen();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LogoWordmark(),
                  SecondaryButton(
                    label: 'Skip',
                    size: ButtonSize.pill,
                    expand: false,
                    onPressed: () => _leave(Routes.signIn),
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollStartNotification>(
                // A swipe by the user restarts the timer.
                onNotification: (n) {
                  if (n.dragDetails != null) _restartTimer();
                  return false;
                },
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: _Dots(
                      count: _slides.length,
                      current: _page,
                      onTap: _goTo,
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Get started',
                    onPressed: () => _leave(Routes.signUp),
                  ),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    label: 'I already have an account',
                    onPressed: () => _leave(Routes.signIn),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        // On short screens the illustration shrinks so the text always fits.
        final panelHeight = (constraints.maxHeight - 190).clamp(120.0, 315.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 26),
              SizedBox(
                height: panelHeight,
                width: double.infinity,
                child: NeuSurface(
                  radius: AppRadii.illustration,
                  shadow: NeuShadow.extraLarge,
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset(
                    slide.asset,
                    semanticsLabel: slide.imageLabel,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text.rich(
                        TextSpan(
                          text: '${slide.line1}\n',
                          children: [
                            TextSpan(
                              text: slide.line2,
                              style: TextStyle(color: c.amberLight),
                            ),
                          ],
                        ),
                        style: AppText.onboardingHeadline,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      slide.body,
                      style: AppText.body.copyWith(
                        fontSize: 15,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.current,
    required this.onTap,
  });

  final int count;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const cell = 30.0;
    const gap = 6.0;
    // The visible pill is 32 tall as designed; invisible 44 px tall tap
    // targets sit on top of it.
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          NeuSurface(
            depth: NeuDepth.pressed,
            shadow: NeuShadow.insetSmall,
            radius: 14,
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  SizedBox(
                    width: cell,
                    height: 24,
                    child: Center(
                      child: AnimatedContainer(
                        duration: AppDurations.medium,
                        curve: Curves.easeOut,
                        width: i == current ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == current ? c.amber : c.track,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < count; i++)
                Semantics(
                  button: true,
                  selected: i == current,
                  label: 'Go to slide ${i + 1} of $count',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: SizedBox(width: cell + gap, height: 44),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
