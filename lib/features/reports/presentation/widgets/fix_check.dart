import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/async_states.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_message.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../application/report_actions.dart';
import '../../data/report_repository.dart';

/// "Yes, fixed" and "Reopen", side by side. Used on Report details and on
/// the "Resolved" notification of the student's own report.
class FixCheckButtons extends ConsumerWidget {
  const FixCheckButtons({super.key, required this.reportId, this.onDone});

  final String reportId;

  /// Called after either answer is saved.
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportActionsProvider(reportId));
    final controller = ref.read(reportActionsProvider(reportId).notifier);

    Future<void> confirm() async {
      if (await controller.confirmFixed()) {
        onDone?.call();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanks for confirming the fix.')),
          );
        }
      }
    }

    Future<void> reopen() async {
      controller.clearError();
      final reopened = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ReopenSheet(reportId: reportId),
      );
      if (reopened == true) {
        onDone?.call();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reopened. Staff will take another look.'),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Yes, fixed',
                size: ButtonSize.medium,
                loading: state.isLoading,
                onPressed: confirm,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SecondaryButton(
                label: 'Reopen',
                onPressed: state.isLoading ? null : reopen,
              ),
            ),
          ],
        ),
        if (state.hasError) ...[
          const SizedBox(height: 12),
          FormMessage(friendlyErrorMessage(state.error!)),
        ],
      ],
    );
  }
}

/// Asks what's still wrong (required) and reopens the report. Pops with
/// true once saved.
class ReopenSheet extends ConsumerStatefulWidget {
  const ReopenSheet({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<ReopenSheet> createState() => _ReopenSheetState();
}

class _ReopenSheetState extends ConsumerState<ReopenSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  static String? _validate(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return "Say what's still wrong";
    if (v.length < ReportRepository.minReopenReason) {
      return 'Add a few more words';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(reportActionsProvider(widget.reportId).notifier)
        .reopen(_reason.text);
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(reportActionsProvider(widget.reportId));
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
                    'Reopen this report',
                    style: AppText.sectionHeading,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'It goes back to campus staff with your note on the '
                  'timeline.',
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                NeuTextField(
                  label: "What's still wrong?",
                  hint: 'e.g. The tap still drips when it is turned off.',
                  controller: _reason,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 3,
                  maxLength: 300,
                  validator: _validate,
                  enabled: !state.isLoading,
                ),
                if (state.hasError) ...[
                  const SizedBox(height: 14),
                  FormMessage(friendlyErrorMessage(state.error!)),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Reopen report',
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
