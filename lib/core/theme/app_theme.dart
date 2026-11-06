import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'text_styles.dart';
import 'tokens.dart';

/// Builds the Material theme from the design tokens. Material widgets we
/// still use (dialogs, snack bars, sheets, text selection) pick up the
/// palette from here, so screens never style them by hand.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(RipotiColors.dark, Brightness.dark);
  static ThemeData get light => _build(RipotiColors.light, Brightness.light);

  static ThemeData _build(RipotiColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.amber,
      onPrimary: c.onAmber,
      secondary: c.plum,
      onSecondary: c.onPlum,
      error: c.error,
      onError: c.base,
      surface: c.base,
      onSurface: c.textPrimary,
    );

    final textTheme = Typography.material2021(platform: TargetPlatform.android)
        .englishLike
        .apply(
          fontFamily: AppText.fontFamily,
          bodyColor: c.textPrimary,
          displayColor: c.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppText.fontFamily,
      scaffoldBackgroundColor: c.base,
      canvasColor: c.base,
      textTheme: textTheme,
      extensions: [c],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.amber,
        selectionColor: c.amber.withValues(alpha: 0.35),
        selectionHandleColor: c.amber,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.amber),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: AppText.bodyStrong.copyWith(
          color: c.base,
          fontFamily: AppText.fontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.base,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        titleTextStyle: AppText.sectionHeading.copyWith(
          color: c.textPrimary,
          fontFamily: AppText.fontFamily,
        ),
        contentTextStyle: AppText.body.copyWith(
          color: c.textBody,
          fontFamily: AppText.fontFamily,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.base,
        modalBackgroundColor: c.base,
        showDragHandle: true,
        dragHandleColor: c.track,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.base,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
    );
  }
}
