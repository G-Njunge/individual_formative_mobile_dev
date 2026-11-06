import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/report_enums.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/neu_surface.dart';
import '../../../core/widgets/neu_switch.dart';
import '../../../core/widgets/neu_text_field.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../core/widgets/segmented_toggle.dart';
import '../../../core/widgets/selectable_tile.dart';
import '../application/new_report_controller.dart';
import 'widgets/report_widgets.dart';

/// The New report form. Text fields are validated by the [Form]; the
/// category, urgency, photos and anonymous switch live in
/// [newReportControllerProvider], which also submits the report.
class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _pickingPhoto = false;

  @override
  void dispose() {
    for (final c in [_title, _description, _location]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addPhoto() async {
    FocusScope.of(context).unfocus();
    setState(() => _pickingPhoto = true);
    await ref.read(newReportControllerProvider.notifier).addPhoto();
    if (mounted) setState(() => _pickingPhoto = false);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    final controller = ref.read(newReportControllerProvider.notifier);
    // Run both so every problem shows at once, not one at a time.
    final selectionsOk = controller.validateSelections();
    final fieldsOk = _formKey.currentState!.validate();
    if (!selectionsOk || !fieldsOk) return;

    final id = await controller.submit(
      title: _title.text,
      description: _description.text,
      location: _location.text,
    );
    if (id != null && mounted) {
      context.pushReplacement(Routes.reportSubmitted(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(newReportControllerProvider);
    final controller = ref.read(newReportControllerProvider.notifier);
    final submitting = state.submission.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.screen,
                  AppSpacing.screen,
                  // Room for the pinned button, so the last row is never
                  // hidden behind it.
                  120,
                ),
                children: [
                  PageHeader(
                    leading: NeuIconButton(
                      icon: AppIcon.close,
                      semanticLabel: 'Close without sending',
                      onPressed: submitting ? null : () => context.pop(),
                    ),
                    title: 'New report',
                  ),
                  const SizedBox(height: 26),
                  _section(
                    title: 'Photos',
                    trailing: Text(
                      'Optional, up to ${AppConfig.maxPhotos}',
                      style: AppText.meta.copyWith(
                        fontSize: 12,
                        color: c.textSecondary,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (var i = 0; i < state.photos.length; i++)
                              AttachedPhotoTile(
                                key: ObjectKey(state.photos[i]),
                                bytes: state.photos[i],
                                index: i,
                                onRemove: () => controller.removePhoto(i),
                              ),
                            if (state.canAddPhoto)
                              AddPhotoTile(
                                loading: _pickingPhoto,
                                onTap: _pickingPhoto || submitting
                                    ? null
                                    : _addPhoto,
                              ),
                          ],
                        ),
                        if (state.photoError != null) ...[
                          const SizedBox(height: 10),
                          _ErrorText(state.photoError!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  _section(
                    title: 'Category',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          label: 'Category, required',
                          container: true,
                          child: GridRows(
                            columns: 3,
                            children: [
                              for (final cat in ReportCategory.values)
                                SelectableTile(
                                  label: cat.label,
                                  selected: state.category == cat,
                                  isRadio: true,
                                  onTap: () => controller.setCategory(cat),
                                ),
                            ],
                          ),
                        ),
                        if (state.showCategoryError) ...[
                          const SizedBox(height: 10),
                          const _ErrorText('Choose a category'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  NeuTextField(
                    label: 'Title',
                    hint: 'e.g. Leaking tap in the Block C washroom',
                    controller: _title,
                    labelStyle: FieldLabelStyle.section,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLength: 80,
                    validator: Validators.reportTitle,
                  ),
                  const SizedBox(height: 26),
                  NeuTextField(
                    label: 'Description',
                    hint: 'What is wrong, and how bad is it?',
                    controller: _description,
                    labelStyle: FieldLabelStyle.section,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 6,
                    minLines: 4,
                    maxLength: AppConfig.maxDescriptionLength,
                    showCounter: true,
                    validator: Validators.description,
                  ),
                  const SizedBox(height: 26),
                  NeuTextField(
                    label: 'Location',
                    hint: 'Building, floor and room',
                    controller: _location,
                    labelStyle: FieldLabelStyle.section,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    maxLength: 120,
                    validator: Validators.location,
                  ),
                  const SizedBox(height: 26),
                  _section(
                    title: 'How urgent is it?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedToggle<Urgency>(
                          semanticLabel: 'Urgency',
                          filledSelection: true,
                          optionHeight: 44,
                          options: [
                            for (final u in Urgency.values)
                              SegmentOption(u, u.label),
                          ],
                          selected: state.urgency,
                          onChanged: controller.setUrgency,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${state.urgency.label}: ${state.urgency.hint}',
                          style: AppText.meta.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  NeuSurface(
                    radius: 22,
                    shadow: NeuShadow.button,
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
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
                              const SizedBox(height: 3),
                              Text(
                                'Staff will not see your name',
                                style: AppText.meta.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        NeuSwitch(
                          value: state.anonymous,
                          semanticLabel: 'Report anonymously',
                          onChanged: submitting
                              ? null
                              : controller.setAnonymous,
                        ),
                      ],
                    ),
                  ),
                  if (state.submission.hasError) ...[
                    const SizedBox(height: 26),
                    FormMessage(friendlyErrorMessage(state.submission.error!)),
                  ],
                ],
              ),
              Positioned(
                left: AppSpacing.screen,
                right: AppSpacing.screen,
                bottom: 22,
                child: PrimaryButton(
                  label: 'Submit report',
                  loading: submitting,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: AppText.formSection),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: AppText.meta.copyWith(
          color: c.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
