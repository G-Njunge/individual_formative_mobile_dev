import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/report_enums.dart';

/// Who a report is assigned to (set by staff in Milestone 4).
class Assignee {
  const Assignee({required this.uid, required this.name, this.team});

  final String uid;
  final String name;
  final String? team;

  factory Assignee.fromJson(Map<String, dynamic> json) => Assignee(
    uid: (json['uid'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    team: json['team'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    if (team != null) 'team': team,
  };
}

/// A report stored at `reports/{id}`.
///
/// Photos are not part of this document. They live in
/// `reports/{id}/photos/{n}` so lists never download them (see README).
class Report {
  const Report({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.urgency,
    required this.status,
    required this.reporterId,
    this.reporterName,
    this.anonymous = false,
    this.photoCount = 0,
    this.assignedTo,
    this.meTooCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int ticketNumber;
  final String title;
  final String description;
  final ReportCategory category;
  final String location;
  final Urgency urgency;
  final ReportStatus status;

  /// Who sent it. Null on anonymous reports: anyone can read a report, so a
  /// stored id would let people match an anonymous report to the same
  /// person's named ones. The link for anonymous reports lives in a private
  /// record only the reporter can read (`users/{uid}/reports/{id}`).
  final String? reporterId;

  /// Null when [anonymous] is true.
  final String? reporterName;
  final bool anonymous;
  final int photoCount;

  final Assignee? assignedTo;
  final int meTooCount;

  /// Null for a moment after creation, until the server timestamp arrives.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get ticketLabel => 'TICKET #$ticketNumber';

  /// True for the reporter's own named reports. Anonymous ones can't be told
  /// apart from the report alone; see `isMyReportProvider`.
  bool isReportedBy(String uid) => reporterId != null && reporterId == uid;

  factory Report.fromJson(String id, Map<String, dynamic> json) {
    final assigned = json['assignedTo'];
    return Report(
      id: id,
      ticketNumber: (json['ticketNumber'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: ReportCategory.fromValue(json['category'] as String?),
      location: (json['location'] as String?) ?? '',
      urgency: Urgency.fromValue(json['urgency'] as String?),
      status: ReportStatus.fromValue(json['status'] as String?),
      reporterId: json['reporterId'] as String?,
      reporterName: json['reporterName'] as String?,
      anonymous: (json['anonymous'] as bool?) ?? false,
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      assignedTo: assigned is Map<String, dynamic>
          ? Assignee.fromJson(assigned)
          : null,
      meTooCount: (json['meTooCount'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Fields the app writes. Timestamps are added by the repository as
  /// server timestamps.
  Map<String, dynamic> toJson() => {
    'ticketNumber': ticketNumber,
    'title': title,
    'description': description,
    'category': category.value,
    'location': location,
    'urgency': urgency.value,
    'status': status.value,
    'reporterId': anonymous ? null : reporterId,
    'reporterName': anonymous ? null : reporterName,
    'anonymous': anonymous,
    'photoCount': photoCount,
    'assignedTo': assignedTo?.toJson(),
    'meTooCount': meTooCount,
  };
}

/// One entry in `reports/{id}/updates`, written by staff when the status
/// changes or they leave a note. Together they make the progress timeline.
class ReportUpdate {
  const ReportUpdate({
    required this.id,
    required this.status,
    this.note,
    required this.byUid,
    required this.byName,
    this.byTeam,
    this.createdAt,
  });

  final String id;
  final ReportStatus status;
  final String? note;
  final String byUid;
  final String byName;
  final String? byTeam;
  final DateTime? createdAt;

  factory ReportUpdate.fromJson(String id, Map<String, dynamic> json) {
    final note = (json['note'] as String?)?.trim();
    return ReportUpdate(
      id: id,
      status: ReportStatus.fromValue(json['status'] as String?),
      note: note == null || note.isEmpty ? null : note,
      byUid: (json['byUid'] as String?) ?? '',
      byName: (json['byName'] as String?) ?? '',
      byTeam: json['byTeam'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.value,
    'note': note,
    'byUid': byUid,
    'byName': byName,
    if (byTeam != null) 'byTeam': byTeam,
  };
}

/// What a student fills in on the New report form.
class ReportDraft {
  const ReportDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.urgency,
    required this.anonymous,
  });

  final String title;
  final String description;
  final ReportCategory category;
  final String location;
  final Urgency urgency;
  final bool anonymous;
}
