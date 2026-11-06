import 'package:flutter/material.dart';

/// Every colour in the app. Screens read these through `context.colors`
/// and never hard-code a hex value.
///
/// The dark palette is the original design. The light palette keeps the same
/// roles on a warm beige base rather than near-white, which was glaring, with
/// a soft cream highlight instead of pure white. Accent text colours are
/// darkened so they stay readable (at least 4.5:1) on that base.
@immutable
class RipotiColors extends ThemeExtension<RipotiColors> {
  const RipotiColors({
    required this.base,
    required this.shadowDark,
    required this.shadowLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textBody,
    required this.amber,
    required this.onAmber,
    required this.amberLight,
    required this.plum,
    required this.onPlum,
    required this.onPlumMuted,
    required this.plumTrackShadow,
    required this.pinkLight,
    required this.pinkFill,
    required this.pinkMark,
    required this.teal,
    required this.divider,
    required this.track,
    required this.error,
    required this.heroOverlay,
    required this.onHero,
  });

  /// Page background and every neumorphic surface.
  final Color base;
  final Color shadowDark;
  final Color shadowLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textBody;

  /// Primary buttons, the + action, the selected urgency level.
  final Color amber;
  final Color onAmber;

  /// Selected chips and tabs, links, the active nav icon, "Submitted".
  final Color amberLight;

  /// Brand fills: logo square, "New today" tile, success badge, switch ON.
  final Color plum;
  final Color onPlum;
  final Color onPlumMuted;
  final Color plumTrackShadow;

  /// "In progress" status text.
  final Color pinkLight;

  /// Fill of the High urgency pill.
  final Color pinkFill;

  /// Completed steps on the progress timeline.
  final Color pinkMark;

  /// "Resolved" status and resolved counts.
  final Color teal;
  final Color divider;

  /// Empty dots, empty timeline steps, unfilled bars.
  final Color track;
  final Color error;

  /// Overlay on top of the paint background of the "Spotted a problem?" card.
  final Color heroOverlay;
  final Color onHero;

  static const dark = RipotiColors(
    base: Color(0xFF2B2230),
    shadowDark: Color(0xFF1A1420),
    shadowLight: Color(0xFF3C3042),
    textPrimary: Color(0xFFF3ECF1),
    textSecondary: Color(0xFFB9A9B6),
    textTertiary: Color(0xFF9C8C99),
    textBody: Color(0xFFD5C7D2),
    amber: Color(0xFFDB9734),
    onAmber: Color(0xFF2A1424),
    amberLight: Color(0xFFF0B45E),
    plum: Color(0xFF680D4E),
    onPlum: Color(0xFFFFFFFF),
    onPlumMuted: Color(0xFFF1D9E8),
    plumTrackShadow: Color(0xFF4A0937),
    pinkLight: Color(0xFFF4A9D8),
    pinkFill: Color(0xFFF4A9D8),
    pinkMark: Color(0xFFD77BB5),
    teal: Color(0xFF74D6CD),
    divider: Color(0xFF3A2F40),
    track: Color(0xFF4A3D50),
    error: Color(0xFFFF8A80),
    heroOverlay: Color(0x80180C1E),
    onHero: Color(0xFFFFFFFF),
  );

  static const light = RipotiColors(
    base: Color(0xFFE9E0D4),
    shadowDark: Color(0xFFC8BBA9),
    shadowLight: Color(0xFFF6F0E7),
    textPrimary: Color(0xFF2B2230),
    textSecondary: Color(0xFF6B5A68),
    textTertiary: Color(0xFF85747F),
    textBody: Color(0xFF4A3D50),
    amber: Color(0xFFDB9734),
    onAmber: Color(0xFF2A1424),
    amberLight: Color(0xFF8F530A),
    plum: Color(0xFF680D4E),
    onPlum: Color(0xFFFFFFFF),
    onPlumMuted: Color(0xFFF1D9E8),
    plumTrackShadow: Color(0xFF4A0937),
    pinkLight: Color(0xFFA1366F),
    pinkFill: Color(0xFFF4A9D8),
    pinkMark: Color(0xFFD77BB5),
    teal: Color(0xFF136660),
    divider: Color(0xFFD8CDBF),
    track: Color(0xFFCCBFAE),
    error: Color(0xFFB32D24),
    heroOverlay: Color(0x80180C1E),
    onHero: Color(0xFFFFFFFF),
  );

  @override
  RipotiColors copyWith() => this;

  @override
  RipotiColors lerp(RipotiColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return RipotiColors(
      base: l(base, other.base),
      shadowDark: l(shadowDark, other.shadowDark),
      shadowLight: l(shadowLight, other.shadowLight),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textBody: l(textBody, other.textBody),
      amber: l(amber, other.amber),
      onAmber: l(onAmber, other.onAmber),
      amberLight: l(amberLight, other.amberLight),
      plum: l(plum, other.plum),
      onPlum: l(onPlum, other.onPlum),
      onPlumMuted: l(onPlumMuted, other.onPlumMuted),
      plumTrackShadow: l(plumTrackShadow, other.plumTrackShadow),
      pinkLight: l(pinkLight, other.pinkLight),
      pinkFill: l(pinkFill, other.pinkFill),
      pinkMark: l(pinkMark, other.pinkMark),
      teal: l(teal, other.teal),
      divider: l(divider, other.divider),
      track: l(track, other.track),
      error: l(error, other.error),
      heroOverlay: l(heroOverlay, other.heroOverlay),
      onHero: l(onHero, other.onHero),
    );
  }
}

/// One neumorphic shadow size: how far the two shadows are offset and how
/// soft they are. Sizes are named after where they are mostly used, but any
/// size can be drawn raised (outside) or pressed (inside).
@immutable
class NeuShadow {
  const NeuShadow(this.offset, this.blur);

  final double offset;
  final double blur;

  // Raised sizes from the spec (offset / blur).
  static const small = NeuShadow(4, 10);
  static const medium = NeuShadow(5, 12);
  static const button = NeuShadow(6, 14);
  static const large = NeuShadow(7, 16);
  static const navBar = NeuShadow(8, 18);
  static const extraLarge = NeuShadow(12, 24);

  // Pressed sizes used by the templates.
  static const insetTiny = NeuShadow(2, 5);
  static const insetSmall = NeuShadow(3, 7);
  static const insetMedium = NeuShadow(4, 9);
  static const insetLarge = NeuShadow(5, 11);
}

class AppRadii {
  AppRadii._();

  static const illustration = 36.0;
  static const card = 24.0;
  static const button = 20.0;
  static const input = 18.0;
  static const iconButton = 16.0;
  static const navBar = 26.0;
  static const tab = 15.0;
  static const smallButton = 14.0;
}

class AppSpacing {
  AppSpacing._();

  static const screen = 22.0;
  static const section = 24.0;
  static const cardPadding = 18.0;
  static const cardGap = 10.0;
  static const listGap = 16.0;

  /// Space at the bottom of scrolling screens so content clears the nav bar.
  static const navClearance = 130.0;
}

class AppDurations {
  AppDurations._();

  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 300);
  static const slide = Duration(milliseconds: 600);
  static const onboardingInterval = Duration(seconds: 4);
}

extension RipotiThemeX on BuildContext {
  RipotiColors get colors => Theme.of(this).extension<RipotiColors>()!;
}
