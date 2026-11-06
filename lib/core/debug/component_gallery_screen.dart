import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/report_enums.dart';
import '../theme/text_styles.dart';
import '../theme/theme_mode_provider.dart';
import '../theme/tokens.dart';
import '../utils/validators.dart';
import '../widgets/app_icons.dart';
import '../widgets/async_states.dart';
import '../widgets/brand.dart';
import '../widgets/buttons.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/neu_card.dart';
import '../widgets/neu_switch.dart';
import '../widgets/neu_text_field.dart';
import '../widgets/password_strength_meter.dart';
import '../widgets/pills.dart';
import '../widgets/progress_timeline.dart';
import '../widgets/report_card.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/selectable_tile.dart';
import '../widgets/stat_tile.dart';

/// Debug-only screen showing every shared component, for comparing against
/// the design images. The text here is placeholder copy, not app data.
class ComponentGalleryScreen extends ConsumerStatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  ConsumerState<ComponentGalleryScreen> createState() =>
      _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState
    extends ConsumerState<ComponentGalleryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController(text: 'example2026');
  final _description = TextEditingController();
  String _role = 'student';
  String _chip = 'All';
  Urgency _urgency = Urgency.medium;
  ReportCategory _category = ReportCategory.water;
  bool _anonymous = false;
  bool _staffNav = false;
  int _navIndex = 0;
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: _staffNav
            ? const [
                NavItem(icon: AppIcon.dashboard, label: 'Dashboard'),
                NavItem(icon: AppIcon.reports, label: 'All reports'),
                NavItem(icon: AppIcon.profile, label: 'Profile'),
              ]
            : const [
                NavItem(icon: AppIcon.home, label: 'Home'),
                NavItem(icon: AppIcon.reports, label: 'Reports'),
                NavItem(
                  icon: AppIcon.plus,
                  label: 'New report',
                  isAction: true,
                ),
                NavItem(
                  icon: AppIcon.bell,
                  label: 'Notifications',
                  showBadge: true,
                ),
                NavItem(icon: AppIcon.profile, label: 'Profile'),
              ],
      ),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              22,
              AppSpacing.screen,
              AppSpacing.navClearance,
            ),
            children: [
              Row(
                children: [
                  NeuIconButton(
                    icon: AppIcon.back,
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text('Component gallery', style: AppText.pageTitle),
                  ),
                  NeuIconButton(
                    icon: AppIcon.close,
                    semanticLabel: 'Close',
                    onPressed: () {},
                  ),
                ],
              ),
              _gap,
              _row('Dark theme', [
                NeuSwitch(
                  value: isDark,
                  semanticLabel: 'Dark theme',
                  onChanged: (v) =>
                      ref.read(themeModeProvider.notifier).setDark(v),
                ),
              ]),
              _row('Staff nav bar', [
                NeuSwitch(
                  value: _staffNav,
                  width: 54,
                  height: 32,
                  semanticLabel: 'Staff nav bar',
                  onChanged: (v) => setState(() {
                    _staffNav = v;
                    _navIndex = 0;
                  }),
                ),
              ]),

              _title('Brand and avatars'),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LogoWordmark(),
                  LogoTile(),
                  InitialsAvatar(name: 'Sample Person'),
                  InitialsAvatar(name: 'Sample Person', large: true),
                ],
              ),

              _title('Buttons'),
              PrimaryButton(
                label: 'Primary (tap to load)',
                loading: _loading,
                onPressed: () async {
                  setState(() => _loading = true);
                  await Future<void>.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _loading = false);
                },
              ),
              _small,
              const PrimaryButton(label: 'Primary disabled', onPressed: null),
              _small,
              SecondaryButton(label: 'Secondary', onPressed: () {}),
              _small,
              SecondaryButton(
                label: 'Sign out',
                foreground: c.error,
                onPressed: () {},
              ),
              _small,
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Yes, fixed',
                      size: ButtonSize.small,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Reopen',
                      size: ButtonSize.small,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              _small,
              SectionHeader(
                title: 'Section heading',
                actionLabel: 'View all',
                onAction: () {},
              ),

              _title('Inputs'),
              const NeuSearchField(hint: 'Search reports or places'),
              _small,
              NeuTextField(
                label: 'Campus email',
                hint: 'you@alustudent.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => Validators.campusEmail(
                  v,
                  allowedDomains: const ['alustudent.com'],
                ),
              ),
              _small,
              NeuTextField(
                label: 'Password',
                controller: _password,
                obscure: true,
                canRevealObscured: true,
                validator: Validators.password,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              PasswordStrengthMeter(password: _password.text),
              _small,
              NeuTextField(
                label: 'Confirm password',
                obscure: true,
                validator: (v) => Validators.confirmPassword(v, _password.text),
              ),
              _small,
              NeuTextField(
                label: 'Description',
                labelStyle: FieldLabelStyle.section,
                controller: _description,
                maxLines: 4,
                minLines: 4,
                maxLength: 300,
                showCounter: true,
                validator: Validators.description,
              ),
              _small,
              SecondaryButton(
                label: 'Validate inputs',
                onPressed: () => _formKey.currentState!.validate(),
              ),

              _title('Toggles'),
              SegmentedToggle<String>(
                options: const [
                  SegmentOption('student', 'Student'),
                  SegmentOption('staff', 'Campus staff'),
                ],
                selected: _role,
                onChanged: (v) => setState(() => _role = v),
              ),
              _small,
              SegmentedToggle<Urgency>(
                filledSelection: true,
                optionHeight: 44,
                options: [
                  for (final u in Urgency.values) SegmentOption(u, u.label),
                ],
                selected: _urgency,
                onChanged: (v) => setState(() => _urgency = v),
              ),
              const SizedBox(height: 12),
              Text(
                '${_urgency.label}: ${_urgency.hint}',
                style: AppText.meta.copyWith(color: c.textSecondary),
              ),
              _small,
              _CategoryGrid(
                selected: _category,
                onSelected: (v) => setState(() => _category = v),
              ),
              _small,
              NeuCard(
                radius: 22,
                shadow: NeuShadow.button,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report anonymously',
                            style: AppText.bodyStrong,
                          ),
                          Text(
                            'Staff will not see your name',
                            style: AppText.meta.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    NeuSwitch(
                      value: _anonymous,
                      semanticLabel: 'Report anonymously',
                      onChanged: (v) => setState(() => _anonymous = v),
                    ),
                  ],
                ),
              ),

              _title('Filter chips'),
              // Chips scroll to the screen edge, so they escape the padding.
              Transform.translate(
                offset: const Offset(-AppSpacing.screen, 0),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  child: FilterChipRow<String>(
                    options: const [
                      ChipOption('All', 'All'),
                      ChipOption('Submitted', 'Submitted'),
                      ChipOption('Under review', 'Under review'),
                      ChipOption('In progress', 'In progress'),
                      ChipOption('Resolved', 'Resolved'),
                    ],
                    selected: _chip,
                    onSelected: (v) => setState(() => _chip = v),
                  ),
                ),
              ),

              _title('Pills'),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (final s in ReportStatus.values) StatusPill(s),
                  for (final u in Urgency.values) UrgencyPill(u),
                ],
              ),

              _title('Report cards'),
              ReportCard(
                category: ReportCategory.water,
                title: 'Sample report title',
                place: 'Place',
                timeLabel: '2h ago',
                status: ReportStatus.inProgress,
                onTap: () {},
              ),
              _small,
              ReportCard(
                category: ReportCategory.safety,
                title: 'Browse variant with a count',
                place: 'Place',
                timeLabel: '3h ago',
                status: ReportStatus.submitted,
                meTooCount: 4,
                onTap: () {},
              ),
              _small,
              QueueReportCard(
                category: ReportCategory.power,
                title: 'Staff queue variant',
                place: 'Place',
                timeLabel: '5h ago',
                status: ReportStatus.submitted,
                urgency: Urgency.high,
                meTooCount: 8,
                onTap: () {},
              ),

              _title('Stat tiles'),
              const Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '6',
                      label: 'New today',
                      tone: StatTileTone.plum,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatTile(
                      value: '9',
                      label: 'In progress',
                      tone: StatTileTone.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '2',
                      label: 'Open reports',
                      valueColor: c.amberLight,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatTile(
                      value: '6',
                      label: 'Resolved',
                      valueColor: c.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: StatTile(
                      value: '8',
                      label: 'Reported',
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatTile(
                      value: '2',
                      label: 'Open',
                      valueColor: c.amberLight,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatTile(
                      value: '6',
                      label: 'Resolved',
                      valueColor: c.teal,
                      compact: true,
                    ),
                  ),
                ],
              ),

              _title('Progress'),
              ProgressTimeline(
                steps: [
                  const TimelineStep(
                    title: 'Submitted',
                    subtitle: 'Today, 7:42 AM',
                    state: TimelineStepState.done,
                  ),
                  const TimelineStep(
                    title: 'Under review',
                    subtitle: '8:05 AM · Facilities team',
                    state: TimelineStepState.done,
                  ),
                  TimelineStep(
                    title: 'In progress',
                    subtitle: '9:30 AM · Staff name',
                    state: TimelineStepState.current,
                    titleColor: c.pinkLight,
                    note: 'A sample staff note sits under the current step.',
                  ),
                  const TimelineStep(
                    title: 'Resolved',
                    subtitle: 'You will be asked to confirm the fix',
                    state: TimelineStepState.upcoming,
                  ),
                ],
              ),
              _small,
              const StatusStepStrip(current: ReportStatus.submitted),

              _title('Illustrations'),
              NeuCard(
                radius: AppRadii.illustration,
                shadow: NeuShadow.extraLarge,
                padding: const EdgeInsets.all(14),
                child: SvgPicture.asset(
                  'assets/illustrations/onboarding_1_see_it.svg',
                  height: 200,
                ),
              ),

              _title('States'),
              const LoadingState(itemCount: 2, itemHeight: 80),
              _small,
              EmptyState(
                title: 'No reports yet',
                message: 'When you report an issue it will show up here.',
                actionLabel: 'Report an issue',
                onAction: () {},
              ),
              _small,
              ErrorState(
                message:
                    'We could not reach the server. Check your '
                    'connection and try again.',
                onRetry: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _gap = SizedBox(height: 18);
  static const _small = SizedBox(height: 16);

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 30, bottom: 14),
    child: Text(text, style: AppText.sectionHeading),
  );

  Widget _row(String label, List<Widget> trailing) => Row(
    children: [
      Expanded(child: Text(label, style: AppText.bodyStrong)),
      ...trailing,
    ],
  );
}

/// The 3-column category grid from New report, here as a preview (the real
/// one is in the reports feature).
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onSelected});

  final ReportCategory selected;
  final ValueChanged<ReportCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridRows(
      columns: 3,
      children: [
        for (final cat in ReportCategory.values)
          SelectableTile(
            label: cat.label,
            selected: cat == selected,
            onTap: () => onSelected(cat),
          ),
      ],
    );
  }
}
