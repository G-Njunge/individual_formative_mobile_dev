import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/neu_text_field.dart';
import '../../../core/widgets/page_layout.dart';
import '../application/auth_controllers.dart';
import '../application/auth_providers.dart';
import '../data/app_user.dart';
import 'forgot_password_sheet.dart';
import 'widgets/auth_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    ref.read(flashMessageProvider.notifier).take();
    // On success the router moves on by itself when the session changes.
    await ref
        .read(signInControllerProvider.notifier)
        .submit(email: _email.text, password: _password.text, role: _role);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final submit = ref.watch(signInControllerProvider);
    // e.g. "your unverified account was removed", set by another screen.
    final notice = ref.watch(flashMessageProvider);

    return Scaffold(
      body: Form(
        key: _formKey,
        child: ScrollWithFooter(
          gap: 28,
          content: [
            Align(
              alignment: Alignment.centerLeft,
              child: NeuIconButton(
                icon: AppIcon.back,
                semanticLabel: 'Back',
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(Routes.onboarding),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LogoTile(),
                  const SizedBox(height: 18),
                  Semantics(
                    header: true,
                    child: Text(
                      'Welcome back',
                      style: AppText.onboardingHeadline.copyWith(
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to report issues and follow their progress.',
                    style: AppText.body.copyWith(
                      fontSize: 15,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            RoleToggle(
              role: _role,
              onChanged: (r) => setState(() => _role = r),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeuTextField(
                  label: 'Campus email',
                  hint: _role.emailHint,
                  controller: _email,
                  height: 56,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => Validators.campusEmail(
                    v,
                    allowedDomains: _role.allowedEmailDomains,
                  ),
                ),
                const SizedBox(height: 20),
                NeuTextField(
                  label: 'Password',
                  controller: _password,
                  height: 56,
                  obscure: true,
                  canRevealObscured: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  validator: (v) => Validators.required(v, field: 'Password'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextLinkButton(
                    label: 'Forgot password?',
                    onPressed: () =>
                        showForgotPasswordSheet(context, email: _email.text),
                  ),
                ),
              ],
            ),
          ],
          footer: [
            if (notice != null) FormMessage(notice, isError: false),
            if (submit.hasError)
              FormMessage(friendlyErrorMessage(submit.error!)),
            PrimaryButton(
              label: _role.signInLabel,
              loading: submit.isLoading,
              onPressed: _submit,
            ),
            AuthSwitchLink(
              prompt: 'New to ${AppConfig.appName}?',
              action: 'Create an account',
              onTap: () => context.go(Routes.signUp),
            ),
          ],
        ),
      ),
    );
  }
}
