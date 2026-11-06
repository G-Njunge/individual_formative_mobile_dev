import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/user_facing_exception.dart';
import '../../../core/models/report_enums.dart';
import '../../auth/data/app_user.dart';
import '../../reports/data/report.dart';
import 'staff_update.dart';

/// Everything staff write: status updates, assignments, after photos,
/// duplicates, and the notifications that go with them.
class StaffRepository {
  StaffRepository(this._db);

  final FirebaseFirestore _db;

  /// Firestore takes at most 500 writes in one batch.
  static const maxBatchWrites = 500;

  /// Writes in the main batch besides notifications: the report, the
  /// timeline entry and the after photo.
  static const _fixedWrites = 3;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  /// Approved staff, for "Assigned to". The query asks only for staff
  /// profiles, which the rules let any verified user read.
  Stream<List<AppUser>> watchStaffMembers() => _db
      .collection('users')
      .where('role', isEqualTo: UserRole.staff.value)
      .where('approved', isEqualTo: true)
      .snapshots()
      .map(
        (q) =>
            [for (final d in q.docs) AppUser.fromJson(d.id, d.data())]
              ..sort((a, b) => a.name.compareTo(b.name)),
      );

  /// The report with this ticket number, for "Duplicate".
  Future<Report?> findByTicket(int ticketNumber) async {
    final q = await _reports
        .where('ticketNumber', isEqualTo: ticketNumber)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return Report.fromJson(q.docs.single.id, q.docs.single.data());
  }

  /// Saves a staff update.
  ///
  /// The report change, the timeline entry, the after photo and a
  /// notification for the reporter and every supporter go in one batch, so
  /// students never see a status change without its notification or the
  /// other way round. Anonymous reporters get no stored notification (staff
  /// don't know who they are); their app builds one from the timeline entry.
  ///
  /// Only if a report has more supporters than fit in one batch (about 500)
  /// are the remaining notifications sent in follow-up batches.
  Future<void> saveUpdate({
    required Report report,
    required StaffUpdateDraft draft,
    required AppUser by,
  }) async {
    final note = draft.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final statusChanged = draft.status != report.status;
    final assigneeChanged = draft.assignee?.uid != report.assignedTo?.uid;
    if (!statusChanged &&
        !hasNote &&
        !assigneeChanged &&
        draft.afterPhoto == null &&
        draft.duplicateOf == null) {
      throw const UserFacingException(
        'Nothing to save yet. Change the status or the assignee, or add a '
        'note.',
      );
    }
    if (hasNote && note.length > AppConfig.maxNoteLength) {
      throw const UserFacingException(
        'Keep the note under ${AppConfig.maxNoteLength} characters.',
      );
    }
    final photo = draft.afterPhoto;
    if (photo != null && draft.status != ReportStatus.resolved) {
      throw const UserFacingException(
        'An after photo can only be added when the report is resolved.',
      );
    }
    if (photo != null && photo.lengthInBytes > AppConfig.photoMaxBytes) {
      throw const UserFacingException(
        'That photo is too large. Try a different one.',
      );
    }

    final reportRef = _reports.doc(report.id);
    try {
      final recipients = await _recipients(report, excluding: by.uid);
      final notification = {
        'type': statusChanged ? 'status' : 'note',
        'reportId': report.id,
        'ticketNumber': report.ticketNumber,
        'reportTitle': report.title,
        'status': draft.status.value,
        'note': hasNote ? note : null,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batches = [_db.batch()];
      final batch = batches.first;
      batch.update(reportRef, {
        'status': draft.status.value,
        'assignedTo': draft.assignee?.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (photo != null) 'hasAfterPhoto': true,
        if (draft.duplicateOf != null)
          'duplicateOf': draft.duplicateOf!.toJson(),
      });
      batch.set(reportRef.collection('updates').doc(), {
        ...ReportUpdate(
          id: '',
          status: draft.status,
          previousStatus: report.status,
          note: hasNote ? note : null,
          byUid: by.uid,
          byName: by.name,
          byTeam: by.team,
        ).toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (photo != null) {
        batch.set(reportRef.collection('photos').doc('after'), {
          'data': Blob(photo),
        });
      }
      var writes = _fixedWrites;
      for (final uid in recipients) {
        if (writes == maxBatchWrites) {
          batches.add(_db.batch());
          writes = 0;
        }
        batches.last.set(
          _db.collection('users').doc(uid).collection('notifications').doc(),
          notification,
        );
        writes++;
      }
      // The first batch carries the report change. The rest are only sent
      // once it has succeeded, so nobody is told about a change that failed.
      for (final b in batches) {
        await b.commit();
      }
    } on FirebaseException catch (e) {
      debugPrint('saveUpdate failed: ${e.code}: ${e.message}');
      final message = switch (e.code) {
        'permission-denied' =>
          "Your update wasn't saved. Your staff access may not be active "
              'yet. Ask the facilities office to approve your account again.',
        'unavailable' || 'deadline-exceeded' =>
          'No connection. Check your internet and try again.',
        'not-found' => 'This report no longer exists.',
        _ => "Your update wasn't saved. Please try again.",
      };
      throw UserFacingException(kDebugMode ? '$message (${e.code})' : message);
    }
  }

  /// Closes [report] as a duplicate of the report with [originalTicket],
  /// telling its reporter and supporters to follow the original instead.
  Future<Report> markDuplicate({
    required Report report,
    required int originalTicket,
    required AppUser by,
  }) async {
    if (originalTicket == report.ticketNumber) {
      throw const UserFacingException(
        "A report can't be a duplicate of itself.",
      );
    }
    final Report? original;
    try {
      original = await findByTicket(originalTicket);
    } on FirebaseException {
      throw const UserFacingException(
        "We couldn't look up that ticket. Check your connection and try "
        'again.',
      );
    }
    if (original == null) {
      throw UserFacingException('There is no ticket #$originalTicket.');
    }
    await saveUpdate(
      report: report,
      by: by,
      draft: StaffUpdateDraft(
        status: ReportStatus.resolved,
        assignee: report.assignedTo,
        note:
            'Duplicate of #$originalTicket (${original.title}). Follow that '
            'ticket for updates.',
        duplicateOf: DuplicateLink(
          id: original.id,
          ticketNumber: original.ticketNumber,
        ),
      ),
    );
    return original;
  }

  /// Who to notify: the named reporter and every supporter, never the staff
  /// member making the change.
  Future<Set<String>> _recipients(
    Report report, {
    required String excluding,
  }) async {
    final supporters = await _reports
        .doc(report.id)
        .collection('supporters')
        .get();
    return {?report.reporterId, for (final d in supporters.docs) d.id}
      ..remove(excluding);
  }
}
