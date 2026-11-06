import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../data/app_user.dart';
import '../../../../core/widgets/segmented_toggle.dart';

/// Student / Campus staff toggle used on both auth forms.
class RoleToggle extends StatelessWidget {
  const RoleToggle({super.key, required this.role, required this.onChanged});

  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedToggle<UserRole>(
      semanticLabel: 'Account type',
      options: [for (final r in UserRole.values) SegmentOption(r, r.label)],
      selected: role,
      onChanged: onChanged,
    );
  }
}

/// "New to Ripoti? **Create an account**".
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: '$prompt $action',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: Text.rich(
              TextSpan(
                text: '$prompt ',
                children: [
                  TextSpan(
                    text: action,
                    recognizer: TapGestureRecognizer()..onTap = onTap,
                    style: TextStyle(
                      color: c.amberLight,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontSize: 14,
                color: c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
