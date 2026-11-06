import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../errors/user_facing_exception.dart';
import 'buttons.dart';
import 'neu_surface.dart';

/// Loading placeholder: pressed "ghost" cards that pulse gently, so loading
/// looks like the content it is waiting for instead of a bare spinner.
class LoadingState extends StatefulWidget {
  const LoadingState({super.key, this.itemCount = 3, this.itemHeight = 112});

  final int itemCount;
  final double itemHeight;

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: FadeTransition(
        opacity: _pulse,
        child: Column(
          children: [
            for (var i = 0; i < widget.itemCount; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.listGap),
              NeuSurface(
                depth: NeuDepth.pressed,
                radius: AppRadii.card,
                height: widget.itemHeight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown when a list loads successfully but has nothing in it.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return NeuSurface(
      depth: NeuDepth.pressed,
      radius: AppRadii.card,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(
              fontSize: 13.5,
              color: c.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            PrimaryButton(
              label: actionLabel!,
              onPressed: onAction,
              size: ButtonSize.small,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown when loading fails. Gives a plain-language message and a retry.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: NeuSurface(
        radius: AppRadii.card,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.cardTitle.copyWith(
                color: c.error,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontSize: 13.5,
                color: c.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              SecondaryButton(
                label: 'Try again',
                onPressed: onRetry,
                size: ButtonSize.small,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders an [AsyncValue] with the app's loading, empty and error states, so
/// every screen that loads data handles all three the same way.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.isEmpty,
    this.empty,
    this.loading,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// When this returns true for loaded data, [empty] is shown instead.
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: true,
      data: (d) =>
          (isEmpty?.call(d) ?? false) && empty != null ? empty! : data(d),
      loading: () => loading ?? const LoadingState(),
      error: (e, _) =>
          ErrorState(message: friendlyErrorMessage(e), onRetry: onRetry),
    );
  }
}

/// Turns exceptions into short messages people can act on. Feature code can
/// throw [UserFacingException] to control the wording.
String friendlyErrorMessage(Object error) {
  if (error is UserFacingException) return error.message;
  final text = error.toString();
  if (text.contains('permission-denied')) {
    return 'You do not have access to this. If you are staff, your account '
        'may still be waiting for approval.';
  }
  if (text.contains('unavailable') || text.contains('network')) {
    return 'We could not reach the server. Check your connection and try '
        'again.';
  }
  return 'Please try again in a moment.';
}
