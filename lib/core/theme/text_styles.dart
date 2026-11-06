import 'package:flutter/material.dart';

/// Type scale from the spec. Styles carry size, weight, height and letter
/// spacing only; colour comes from the theme (textPrimary by default) or is
/// added at the call site from `context.colors`.
class AppText {
  AppText._();

  static const fontFamily = 'PlusJakartaSans';

  static const onboardingHeadline = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.6,
  );
  static const screenTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );
  static const pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );
  static const greetingName = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );
  static const sectionHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );
  static const formSection = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
  static const cardTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const body = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );
  static const bodyStrong = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );
  static const meta = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500);
  static const categoryLabel = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.6,
  );
  static const fieldLabel = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
  );
  static const input = TextStyle(fontSize: 15, fontWeight: FontWeight.w400);
  static const buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const link = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
  static const pill = TextStyle(fontSize: 12, fontWeight: FontWeight.w800);
  static const statNumber = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1,
  );
  static const statLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
}
