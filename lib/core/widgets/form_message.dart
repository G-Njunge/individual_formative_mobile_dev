import 'package:flutter/material.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'neu_surface.dart';

/// A message for the whole form (e.g. "That email and password do not
/// match"), shown above the submit button and read out by screen readers.
class FormMessage extends StatelessWidget {
  const FormMessage(this.message, {super.key, this.isError = true});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: NeuSurface(
        depth: NeuDepth.pressed,
        radius: AppRadii.input,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: isError ? Border.all(color: c.error, width: 1.5) : null,
        child: Text(
          message,
          style: AppText.meta.copyWith(
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w700,
            color: isError ? c.error : c.textBody,
          ),
        ),
      ),
    );
  }
}
