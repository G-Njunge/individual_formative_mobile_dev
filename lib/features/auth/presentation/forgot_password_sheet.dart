import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/neu_text_field.dart';
import '../application/auth_controllers.dart';
import 'widgets/auth_widgets.dart';

Future<void> showForgotPasswordSheet(
  BuildContext context, {
  String email = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ForgotPasswordSheet(initialEmail: email),
  );
}

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet({required this.initialEmail});

  final String initialEmail;

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail.trim());

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(passwordResetControllerProvider.notifier).send(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(passwordResetControllerProvider);
    final sent = state.value ?? false;

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: const Text(
                    'Reset your password',
                    style: AppText.pageTitle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sent
                      ? 'If an account exists for ${_email.text.trim()}, a '
                            'reset link is on its way. Check your spam folder '
                            'too.'
                      : "Enter your campus email and we'll send you a link to "
                            'choose a new password.',
                  style: AppText.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: 20),
                if (!sent) ...[
                  NeuTextField(
                    label: 'Campus email',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    validator: Validators.campusEmail,
                  ),
                  const SizedBox(height: 20),
                  if (state.hasError) ...[
                    FormMessage(friendlyErrorMessage(state.error!)),
                    const SizedBox(height: 16),
                  ],
                  PrimaryButton(
                    label: 'Send reset link',
                    loading: state.isLoading,
                    onPressed: _send,
                  ),
                ] else
                  PrimaryButton(
                    label: 'Back to sign in',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
