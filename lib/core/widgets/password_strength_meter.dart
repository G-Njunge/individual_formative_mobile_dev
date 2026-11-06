import 'package:flutter/material.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../utils/validators.dart';
import 'neu_surface.dart';

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
