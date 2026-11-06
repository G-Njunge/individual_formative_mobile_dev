import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'app_icons.dart';
import 'buttons.dart';
import 'neu_surface.dart';

enum FieldLabelStyle {
  /// 13.5/700, used on the auth forms.
  compact,

  /// 15/800, used as section headings on the report forms.
  section,
}

/// Pressed input with its label above and its error (or helper) text below.
///
/// It wraps a [FormField] rather than using [TextFormField]'s built-in
/// decoration so the error can be drawn exactly as designed: a red outline
/// around the pressed surface and bold red text underneath.
class NeuTextField extends StatefulWidget {
  const NeuTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.obscure = false,
    this.canRevealObscured = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCounter = false,
    this.helperText,
    this.leadingSearchIcon = false,
    this.trailing,
    this.labelStyle = FieldLabelStyle.compact,
    this.height = 54,
    this.radius = AppRadii.input,
    this.enabled = true,
    this.focusNode,
    this.semanticLabel,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool obscure;

  /// Adds a "Show" / "Hide" text button for password fields.
  final bool canRevealObscured;
  final int maxLines;
  final int? minLines;

  /// Hard limit on characters typed.
  final int? maxLength;

  /// Shows "92 / 300" under the field (needs [maxLength]).
  final bool showCounter;
  final String? helperText;

  /// The only leading icon the design allows.
  final bool leadingSearchIcon;
  final Widget? trailing;
  final FieldLabelStyle labelStyle;

  /// Height of single-line fields. Multi-line fields size to their content.
  final double height;
  final double radius;
  final bool enabled;
  final FocusNode? focusNode;

  /// For fields without a visible label (search).
  final String? semanticLabel;

  @override
  State<NeuTextField> createState() => _NeuTextFieldState();
}

class _NeuTextFieldState extends State<NeuTextField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  TextEditingController? _ownController;
  bool _revealed = false;

  TextEditingController get _controller =>
      widget.controller ??
      (_ownController ??= TextEditingController(text: widget.initialValue));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncField);
  }

  @override
  void didUpdateWidget(NeuTextField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _ownController)?.removeListener(_syncField);
      _controller.addListener(_syncField);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncField);
    _ownController?.dispose();
    super.dispose();
  }

  /// Keeps the form field's value in step with the controller, including
  /// changes made in code (e.g. clearing the form).
  void _syncField() {
    final field = _fieldKey.currentState;
    if (field != null && field.value != _controller.text) {
      field.didChange(_controller.text);
    }
    if (widget.showCounter) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final multiline = widget.maxLines > 1;

    return FormField<String>(
      key: _fieldKey,
      initialValue: _controller.text,
      validator: widget.validator,
      enabled: widget.enabled,
      builder: (field) {
        final error = field.errorText;
        final input = TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: widget.obscure && !_revealed,
          keyboardType: multiline
              ? TextInputType.multiline
              : widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofillHints: widget.autofillHints,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.minLines,
          inputFormatters: widget.maxLength == null
              ? null
              : [LengthLimitingTextInputFormatter(widget.maxLength)],
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          cursorColor: c.amber,
          style: (multiline ? AppText.body : AppText.input).copyWith(
            color: c.textPrimary,
            fontSize: multiline ? 14 : 15,
            letterSpacing: widget.obscure && !_revealed ? 2 : null,
          ),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: widget.hint,
            hintStyle: AppText.input.copyWith(
              color: c.textTertiary,
              fontSize: multiline ? 14 : 15,
            ),
          ),
        );

        final surface = NeuSurface(
          depth: NeuDepth.pressed,
          radius: widget.radius,
          height: multiline ? null : widget.height,
          border: error == null ? null : Border.all(color: c.error, width: 1.5),
          padding: EdgeInsets.fromLTRB(
            18,
            multiline ? 16 : 0,
            widget.trailing != null || widget.canRevealObscured ? 8 : 18,
            multiline ? 16 : 0,
          ),
          child: Row(
            crossAxisAlignment: multiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (widget.leadingSearchIcon) ...[
                AppIconView(
                  AppIcon.search,
                  color: c.textTertiary,
                  size: 18,
                  strokeWidth: 2.2,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(child: input),
              if (widget.canRevealObscured)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextLinkButton(
                    label: _revealed ? 'Hide' : 'Show',
                    onPressed: () => setState(() => _revealed = !_revealed),
                  ),
                ),
              ?widget.trailing,
            ],
          ),
        );

        final below = <Widget>[
          if (error != null)
            Text(
              error,
              style: AppText.meta.copyWith(
                color: c.error,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (widget.helperText != null)
            Text(
              widget.helperText!,
              style: AppText.meta.copyWith(color: c.textSecondary),
            ),
          if (widget.showCounter && widget.maxLength != null)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_controller.text.characters.length} / ${widget.maxLength}',
                style: AppText.meta.copyWith(
                  color: c.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
        ];

        return Semantics(
          label: widget.semanticLabel,
          textField: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.label != null) ...[
                Text(
                  widget.label!,
                  style: widget.labelStyle == FieldLabelStyle.compact
                      ? AppText.fieldLabel
                      : AppText.formSection,
                ),
                SizedBox(
                  height: widget.labelStyle == FieldLabelStyle.compact ? 9 : 10,
                ),
              ],
              surface,
              for (final w in below) ...[const SizedBox(height: 8), w],
            ],
          ),
        );
      },
    );
  }
}

/// Search box used on Home and Browse: pressed, 54 tall, radius 20, with the
/// search icon. Search runs on the device (see README).
class NeuSearchField extends StatelessWidget {
  const NeuSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return NeuTextField(
      hint: hint,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      leadingSearchIcon: true,
      radius: AppRadii.button,
      textInputAction: TextInputAction.search,
      semanticLabel: 'Search reports',
    );
  }
}
