import 'package:flutter/material.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../utils/validators.dart';
import 'app_icons.dart';
import 'neu_surface.dart';

/// The password rules as a checklist that ticks off while you type, so
/// people know what is missing before they press Create account.
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in PasswordRequirement.values)
          Builder(
            builder: (context) {
              final met = rule.isMetBy(password);
              return Semantics(
                label: '${rule.label}: ${met ? 'done' : 'not yet'}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 16,
                        child: Center(
                          child: met
                              ? AppIconView(
                                  AppIcon.check,
                                  color: c.teal,
                                  size: 16,
                                  strokeWidth: 2.6,
                                )
                              : Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: c.textSecondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rule.label,
                        style: AppText.meta.copyWith(
                          color: met ? c.teal : c.textSecondary,
                          fontWeight: met ? FontWeight.w700 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Three bars plus a word. Filled bars are amber; empty bars are pressed.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final strength = Validators.passwordStrength(password);
    final filled = strength.bars;
    final (word, wordColor) = switch (strength) {
      PasswordStrength.none => ('', c.textSecondary),
      PasswordStrength.weak => ('Weak', c.error),
      PasswordStrength.medium => ('Medium', c.amberLight),
      PasswordStrength.strong => ('Strong', c.teal),
    };

    return Semantics(
      label: word.isEmpty ? null : 'Password strength: $word',
      liveRegion: true,
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: i < filled
                  ? AnimatedContainer(
                      duration: AppDurations.fast,
                      height: 6,
                      decoration: BoxDecoration(
                        color: strength == PasswordStrength.weak
                            ? c.error
                            : c.amber,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )
                  : const NeuSurface(
                      depth: NeuDepth.pressed,
                      shadow: NeuShadow(2, 3),
                      radius: 3,
                      height: 6,
                    ),
            ),
          ],
          SizedBox(
            width: 66,
            child: Text(
              word,
              textAlign: TextAlign.right,
              style: AppText.meta.copyWith(
                fontWeight: FontWeight.w700,
                color: wordColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
