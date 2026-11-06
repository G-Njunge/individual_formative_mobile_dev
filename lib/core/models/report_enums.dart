import 'package:flutter/painting.dart';

import '../theme/tokens.dart';

/// Lifecycle of a report, in order. `value` is what Firestore stores.
enum ReportStatus {
  submitted('submitted', 'Submitted', 'Submitted'),
  underReview('under_review', 'Under review', 'Review'),
  inProgress('in_progress', 'In progress', 'In progress'),
  resolved('resolved', 'Resolved', 'Resolved');

  const ReportStatus(this.value, this.label, this.shortLabel);

  final String value;
  final String label;

  /// Used on the four-step strip, where space is tight.
  final String shortLabel;

  bool get isOpen => this != ReportStatus.resolved;

  static ReportStatus fromValue(String? value) =>
      ReportStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => ReportStatus.submitted,
      );

  /// A status is always shown as a word; this colour is only the text tint.
  Color color(RipotiColors c) => switch (this) {
    ReportStatus.submitted => c.amberLight,
    ReportStatus.underReview => c.textBody,
    ReportStatus.inProgress => c.pinkLight,
    ReportStatus.resolved => c.teal,
  };
}

enum Urgency {
  low('low', 'Low', 'it can wait a few days.'),
  medium('medium', 'Medium', 'it affects people today.'),
  high('high', 'High', 'it is unsafe or blocks a whole building.');

  const Urgency(this.value, this.label, this.hint);

  final String value;
  final String label;
  final String hint;

  static Urgency fromValue(String? value) => Urgency.values.firstWhere(
    (u) => u.value == value,
    orElse: () => Urgency.medium,
  );
}

enum ReportCategory {
  water('water', 'Water'),
  power('power', 'Power'),
  furniture('furniture', 'Furniture'),
  sanitation('sanitation', 'Sanitation'),
  safety('safety', 'Safety'),
  other('other', 'Other');

  const ReportCategory(this.value, this.label);

  final String value;
  final String label;

  static ReportCategory fromValue(String? value) => ReportCategory.values
      .firstWhere((c) => c.value == value, orElse: () => ReportCategory.other);
}
