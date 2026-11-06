import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/neu_text_field.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../core/widgets/password_strength_meter.dart';
import '../application/auth_controllers.dart';
import '../data/app_user.dart';
import 'widgets/auth_widgets.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _staffId = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserRole _role = UserRole.student;

  /// Fields check themselves as you type, but only after the first submit,
  /// so nobody is shown errors before they've finished typing.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    // Redraws the strength meter as the password changes.
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _staffId, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;
    // On success the router opens "Check your email" by itself.
    await ref
        .read(signUpControllerProvider.notifier)
        .submit(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          role: _role,
          staffId: _role == UserRole.staff ? _staffId.text : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final submit = ref.watch(signUpControllerProvider);
    final isStaff = _role == UserRole.staff;

    return Scaffold(
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: ScrollWithFooter(
          content: [
            PageHeader(
              leading: NeuIconButton(
                icon: AppIcon.back,
                semanticLabel: 'Back to sign in',
                onPressed: () => context.go(Routes.signIn),
              ),
              title: 'Create account',
            ),
            RoleToggle(
              role: _role,
              onChanged: (r) => setState(() => _role = r),
            ),
            NeuTextField(
              label: 'Full name',
              controller: _name,
              height: 52,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: Validators.fullName,
            ),
            NeuTextField(
              label: 'Campus email',
              hint: _role.emailHint,
              controller: _email,
              height: 52,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) => Validators.campusEmail(
                v,
                allowedDomains: _role.allowedEmailDomains,
              ),
            ),
            if (isStaff)
              NeuTextField(
                label: 'Staff ID',
                hint: 'e.g. FAC-0231',
                controller: _staffId,
                height: 52,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                helperText:
                    'Staff accounts are approved by the facilities office.',
                validator: Validators.staffId,
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeuTextField(
                  label: 'Password',
                  controller: _password,
                  height: 52,
                  obscure: true,
                  canRevealObscured: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                ),
                const SizedBox(height: 9),
                PasswordStrengthMeter(password: _password.text),
              ],
            ),
            NeuTextField(
              label: 'Confirm password',
              controller: _confirm,
              height: 52,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) => Validators.confirmPassword(v, _password.text),
            ),
          ],
          footer: [
            if (submit.hasError)
              FormMessage(friendlyErrorMessage(submit.error!)),
            PrimaryButton(
              label: 'Create account',
              loading: submit.isLoading,
              onPressed: _submit,
            ),
            AuthSwitchLink(
              prompt: 'Already have an account?',
              action: 'Sign in',
              onTap: () => context.go(Routes.signIn),
            ),
          ],
        ),
      ),
    );
  }
}
