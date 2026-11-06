import 'dart:typed_data';

import '../../../core/models/report_enums.dart';
import '../../reports/data/report.dart';

/// What staff fill in on "Review and update".
class StaffUpdateDraft {
  const StaffUpdateDraft({
    required this.status,
    this.assignee,
    this.note,
    this.afterPhoto,
    this.duplicateOf,
  });

  final ReportStatus status;

  /// Null means nobody is assigned.
  final Assignee? assignee;

  /// Shown to the reporter on the timeline and in their notification.
  final String? note;

  /// Photo of the fix. Only allowed when [status] is resolved.
  final Uint8List? afterPhoto;
  final DuplicateLink? duplicateOf;
}
