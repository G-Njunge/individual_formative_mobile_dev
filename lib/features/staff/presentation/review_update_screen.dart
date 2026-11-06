import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/user_facing_exception.dart';
import '../../../core/models/report_enums.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/neu_card.dart';
import '../../../core/widgets/neu_surface.dart';
import '../../../core/widgets/neu_text_field.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../core/widgets/selectable_tile.dart';
import '../../auth/application/auth_providers.dart';
import '../../reports/application/report_filters.dart';
import '../../reports/application/report_providers.dart';
import '../../reports/data/report.dart';
import '../application/staff_providers.dart';
import '../data/staff_update.dart';

/// Staff "Review and update": the ticket summary, then status, assignee,
/// a note to the reporter and (when resolved) a photo of the fix.
class ReviewUpdateScreen extends ConsumerWidget {
  const ReviewUpdateScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider(reportId));
    return Scaffold(
      body: SafeArea(
        child: AsyncValueView(
          value: report,
          onRetry: () => ref.invalidate(reportProvider(reportId)),
          data: (r) => r == null
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: EmptyState(
                    title: 'Report not found',
                    message: 'It may have been removed.',
                    actionLabel: 'Back',
                    onAction: () => context.pop(),
                  ),
                )
              : _ReviewForm(report: r),
        ),
      ),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({required this.report});

  final Report report;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  final _note = TextEditingController();

  // Start from the report as it is. The report is live, so these are only
  // the starting point: staff edits aren't overwritten while they type.
  late ReportStatus _status = widget.report.status;
  late Assignee? _assignee = widget.report.assignedTo;
  Uint8List? _afterPhoto;
  String? _photoError;
  bool _pickingPhoto = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _edited() =>
      ref.read(staffUpdateControllerProvider.notifier).clearError();

  Future<void> _pickAfterPhoto() async {
    setState(() {
      _pickingPhoto = true;
      _photoError = null;
    });
    try {
      final bytes = await ref.read(photoPickerProvider).pick();
      if (bytes != null && mounted) setState(() => _afterPhoto = bytes);
    } on UserFacingException catch (e) {
      if (mounted) setState(() => _photoError = e.message);
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _chooseAssignee() async {
    FocusScope.of(context).unfocus();
    final choice = await showModalBottomSheet<_AssigneeChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssigneeSheet(current: _assignee),
    );
    if (choice == null || !mounted) return;
    setState(() => _assignee = choice.assignee);
    _edited();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(staffUpdateControllerProvider.notifier)
        .save(
          widget.report,
          StaffUpdateDraft(
            status: _status,
            assignee: _assignee,
            note: _note.text,
            afterPhoto: _status == ReportStatus.resolved ? _afterPhoto : null,
          ),
        );
    if (!saved || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update saved for #${widget.report.ticketNumber}.'),
      ),
    );
    context.pop();
  }

  Future<void> _duplicate() async {
    FocusScope.of(context).unfocus();
    final original = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DuplicateSheet(report: widget.report),
    );
    if (original == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '#${widget.report.ticketNumber} closed as a duplicate of #$original.',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final report = widget.report;
    final save = ref.watch(staffUpdateControllerProvider);
    final busy = save.isLoading;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.screen,
            AppSpacing.screen,
            // Room for the pinned buttons.
            120,
          ),
          children: [
            PageHeader(
              leading: NeuIconButton(
                icon: AppIcon.back,
                semanticLabel: 'Back',
                onPressed: busy ? null : () => context.pop(),
              ),
              overline: report.ticketLabel,
              title: 'Review and update',
            ),
            const SizedBox(height: 22),
            _TicketSummary(report: report),
            if (report.duplicateOf case final dup?) ...[
              const SizedBox(height: 12),
              Text(
                'Closed as a duplicate of #${dup.ticketNumber}.',
                style: AppText.meta.copyWith(color: c.textSecondary),
              ),
            ],
            const SizedBox(height: 26),
            _section(
              'Update status',
              Semantics(
                container: true,
                label: 'Status',
                child: GridRows(
                  columns: 2,
                  children: [
                    for (final s in ReportStatus.values)
                      SelectableTile(
                        label: s.label,
                        selected: _status == s,
                        selectedColor: s.color(c),
                        isRadio: true,
                        height: 54,
                        fontSize: 14.5,
                        onTap: () {
                          setState(() => _status = s);
                          _edited();
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            _section(
              'Assigned to',
              NeuSurface(
                depth: NeuDepth.pressed,
                shadow: NeuShadow.insetMedium,
                radius: AppRadii.input,
                height: 58,
                padding: const EdgeInsets.only(left: 18, right: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _assignee == null
                            ? 'Not assigned yet'
                            : [_assignee!.name, ?_assignee!.team].join(', '),
                        style: AppText.bodyStrong.copyWith(
                          color: _assignee == null
                              ? c.textSecondary
                              : c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Semantics(
                      hint: 'Choose who is fixing it',
                      child: TextLinkButton(
                        label: _assignee == null ? 'Assign' : 'Change',
                        onPressed: busy ? null : _chooseAssignee,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            NeuTextField(
              label: 'Note to the reporter',
              hint:
                  'e.g. Plumber on the way. Water will be off for 30 minutes.',
              controller: _note,
              labelStyle: FieldLabelStyle.section,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
              minLines: 3,
              maxLength: AppConfig.maxNoteLength,
              enabled: !busy,
              onChanged: (_) => _edited(),
            ),
            const SizedBox(height: 10),
            Text(
              report.anonymous
                  ? 'Everyone who backed this report gets notified. The '
                        'reporter sent it anonymously and is told without you '
                        'seeing who they are.'
                  : 'Everyone who backed this report gets notified.',
              style: AppText.meta.copyWith(color: c.textSecondary),
            ),
            if (_status == ReportStatus.resolved) ...[
              const SizedBox(height: 26),
              _section(
                'After photo',
                _AfterPhotoPicker(
                  reportId: report.id,
                  hasSaved: report.hasAfterPhoto,
                  picked: _afterPhoto,
                  loading: _pickingPhoto,
                  error: _photoError,
                  onPick: busy || _pickingPhoto ? null : _pickAfterPhoto,
                  onRemove: busy
                      ? null
                      : () => setState(() => _afterPhoto = null),
                ),
              ),
            ],
            if (save.hasError) ...[
              const SizedBox(height: 22),
              FormMessage(friendlyErrorMessage(save.error!)),
            ],
          ],
        ),
        Positioned(
          left: AppSpacing.screen,
          right: AppSpacing.screen,
          bottom: 22,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: SecondaryButton(
                  label: 'Duplicate',
                  size: ButtonSize.large,
                  onPressed: busy ? null : _duplicate,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: PrimaryButton(
                  label: 'Save update',
                  loading: busy,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(header: true, child: Text(title, style: AppText.formSection)),
      const SizedBox(height: 12),
      child,
    ],
  );
}

/// The raised card at the top: first photo, category and urgency, title,
/// place, backers, the reporter's words and who sent it.
class _TicketSummary extends ConsumerWidget {
  const _TicketSummary({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final photo = report.photoCount == 0
        ? null
        : ref.watch(reportPhotosProvider(report.id)).value?.firstOrNull;
    final reporter = report.anonymous || report.reporterName == null
        ? 'Reported anonymously.'
        : 'Reported by ${shortStaffName(report.reporterName!, null)}';

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (report.photoCount > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox.square(
                    dimension: 84,
                    child: photo == null
                        ? ColoredBox(color: c.track)
                        : Image.memory(
                            photo,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            semanticLabel: 'Photo of the problem',
                          ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report.category.label} · ${report.urgency.label}'
                          .toUpperCase(),
                      style: AppText.categoryLabel.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(report.title, style: AppText.cardTitle),
                    const SizedBox(height: 6),
                    Text(
                      '${report.location} · ${report.meTooCount} me too',
                      style: AppText.meta.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '“${report.description}”\n$reporter',
            style: AppText.body.copyWith(
              fontSize: 14,
              height: 1.5,
              color: c.textBody,
            ),
          ),
        ],
      ),
    );
  }
}

/// "+ Add a photo of the fix", or the chosen photo with a way to remove it.
/// If an after photo was saved earlier it is shown until replaced.
class _AfterPhotoPicker extends ConsumerWidget {
  const _AfterPhotoPicker({
    required this.reportId,
    required this.hasSaved,
    required this.picked,
    required this.loading,
    required this.error,
    required this.onPick,
    required this.onRemove,
  });

  final String reportId;
  final bool hasSaved;
  final Uint8List? picked;
  final bool loading;
  final String? error;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final saved = hasSaved && picked == null
        ? ref.watch(reportAfterPhotoProvider(reportId)).value
        : null;
    final shown = picked ?? saved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shown != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.memory(
                shown,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                semanticLabel: 'Photo of the fix',
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (picked != null)
                TextLinkButton(label: 'Remove', onPressed: onRemove)
              else
                TextLinkButton(label: 'Replace photo', onPressed: onPick),
            ],
          ),
        ] else
          NeuPressable(
            onTap: onPick,
            semanticLabel: 'Add a photo of the fix',
            builder: (context, pressed) => NeuSurface(
              depth: NeuDepth.pressed,
              shadow: pressed ? NeuShadow.insetMedium : NeuShadow.insetLarge,
              radius: 22,
              height: 120,
              child: Center(
                child: loading
                    ? SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: c.teal,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+',
                            style: TextStyle(
                              fontSize: 28,
                              height: 1,
                              fontWeight: FontWeight.w500,
                              color: c.teal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add a photo of the fix',
                            style: AppText.link.copyWith(
                              fontSize: 14,
                              color: c.teal,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: AppText.meta.copyWith(
              color: c.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

/// What the assignee sheet returns: a staff member, or nobody.
class _AssigneeChoice {
  const _AssigneeChoice(this.assignee);
  final Assignee? assignee;
}

/// Approved staff to pick from, with the signed-in staff member first.
class _AssigneeSheet extends ConsumerWidget {
  const _AssigneeSheet({required this.current});

  final Assignee? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final me = ref.watch(sessionProvider).profile;
    final staff = ref.watch(staffMembersProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: const Text('Assign to', style: AppText.sectionHeading),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: AsyncValueView(
                  value: staff,
                  onRetry: () => ref.invalidate(staffMembersProvider),
                  data: (people) {
                    final sorted = [
                      ...people.where((p) => p.uid == me?.uid),
                      ...people.where((p) => p.uid != me?.uid),
                    ];
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        for (final p in sorted)
                          _AssigneeRow(
                            label: p.uid == me?.uid
                                ? '${p.name} (you)'
                                : p.name,
                            detail: p.team,
                            selected: current?.uid == p.uid,
                            onTap: () => Navigator.pop(
                              context,
                              _AssigneeChoice(
                                Assignee(
                                  uid: p.uid,
                                  name: p.name,
                                  team: p.team,
                                ),
                              ),
                            ),
                          ),
                        _AssigneeRow(
                          label: 'Nobody yet',
                          detail: 'Leave it unassigned',
                          selected: current == null,
                          color: c.textSecondary,
                          onTap: () => Navigator.pop(
                            context,
                            const _AssigneeChoice(null),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssigneeRow extends StatelessWidget {
  const _AssigneeRow({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      excludeSemantics: true,
      label: [label, ?detail].join(', '),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.bodyStrong.copyWith(
                        color: selected ? c.amberLight : color ?? c.textPrimary,
                      ),
                    ),
                    if (detail != null && detail!.isNotEmpty)
                      Text(
                        detail!,
                        style: AppText.meta.copyWith(color: c.textSecondary),
                      ),
                  ],
                ),
              ),
              if (selected)
                AppIconView(AppIcon.check, color: c.amberLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks for the original ticket number and closes this report as its
/// duplicate. Pops with the original's number once saved.
class _DuplicateSheet extends ConsumerStatefulWidget {
  const _DuplicateSheet({required this.report});

  final Report report;

  @override
  ConsumerState<_DuplicateSheet> createState() => _DuplicateSheetState();
}

class _DuplicateSheetState extends ConsumerState<_DuplicateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _ticket = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Don't carry an error from the main form into the sheet.
    Future.microtask(
      () => ref.read(staffUpdateControllerProvider.notifier).clearError(),
    );
  }

  @override
  void dispose() {
    _ticket.dispose();
    super.dispose();
  }

  static String? _validate(String? value) {
    final v = value?.trim().replaceFirst('#', '') ?? '';
    if (v.isEmpty) return 'Enter the ticket number';
    if (int.tryParse(v) == null) return 'Use numbers only, e.g. 1040';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final number = int.parse(_ticket.text.trim().replaceFirst('#', ''));
    final saved = await ref
        .read(staffUpdateControllerProvider.notifier)
        .markDuplicate(widget.report, number);
    if (saved && mounted) Navigator.pop(context, number);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(staffUpdateControllerProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: const Text(
                    'Mark as a duplicate',
                    style: AppText.sectionHeading,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This report will be resolved and its reporter and '
                  'backers told to follow the original ticket.',
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                NeuTextField(
                  label: 'Original ticket number',
                  hint: 'e.g. 1040',
                  controller: _ticket,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: _validate,
                  enabled: !state.isLoading,
                ),
                if (state.hasError) ...[
                  const SizedBox(height: 14),
                  FormMessage(friendlyErrorMessage(state.error!)),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Close as duplicate',
                  loading: state.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
