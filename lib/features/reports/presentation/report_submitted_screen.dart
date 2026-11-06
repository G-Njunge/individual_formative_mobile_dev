import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/neu_card.dart';
import '../../../core/widgets/neu_surface.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../core/widgets/pills.dart';
import '../../../core/widgets/progress_timeline.dart';
import '../../auth/application/auth_providers.dart';
import '../application/report_providers.dart';

/// Shown once, straight after a report is saved. It replaces the New report
/// page, so going back returns to the tabs rather than to the sent form.
class ReportSubmittedScreen extends ConsumerWidget {
  const ReportSubmittedScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final report = ref.watch(reportProvider(reportId));
    final firstName = ref.watch(sessionProvider).profile?.firstName;

    return Scaffold(
      body: ScrollWithFooter(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
        gap: 26,
        content: [
          const _CelebrationPanel(),
          Column(
            children: [
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  'Report submitted',
                  textAlign: TextAlign.center,
                  style: AppText.screenTitle.copyWith(
                    fontSize: 27,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${firstName == null ? 'Thanks' : 'Thanks, $firstName'}. '
                'Campus staff have your report and you will be notified '
                'when the status changes.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          AsyncValueView(
            value: report,
            loading: const LoadingState(itemCount: 1, itemHeight: 150),
            data: (r) => r == null
                ? const SizedBox.shrink()
                : NeuCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.ticketLabel,
                                style: AppText.categoryLabel.copyWith(
                                  fontSize: 12,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                            StatusPill(r.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(r.title, style: AppText.cardTitle),
                        const SizedBox(height: 16),
                        StatusStepStrip(current: r.status),
                      ],
                    ),
                  ),
          ),
        ],
        footer: [
          PrimaryButton(
            label: 'Track this report',
            onPressed: () =>
                context.pushReplacement(Routes.reportDetails(reportId)),
          ),
          SecondaryButton(
            label: 'Back to home',
            onPressed: () => context.go(Routes.home),
          ),
        ],
      ),
    );
  }
}

/// The cheering illustration in a raised panel, with the plum check badge
/// overlapping its top-right corner.
class _CelebrationPanel extends StatelessWidget {
  const _CelebrationPanel();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        NeuSurface(
          radius: AppRadii.illustration,
          shadow: NeuShadow.extraLarge,
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            height: 230,
            width: double.infinity,
            child: SvgPicture.asset(
              'assets/illustrations/report_submitted.svg',
              semanticsLabel: 'A student cheering with both arms up',
            ),
          ),
        ),
        Positioned(
          top: -14,
          right: -6,
          child: ExcludeSemantics(
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: c.plum,
                shape: BoxShape.circle,
                boxShadow: NeuSurface.raisedShadows(c, NeuShadow.button),
              ),
              alignment: Alignment.center,
              child: AppIconView(
                AppIcon.check,
                color: c.amberLight,
                size: 30,
                strokeWidth: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
