import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/user_facing_exception.dart';
import '../../../core/models/report_enums.dart';
import '../../auth/data/app_user.dart';
import 'report.dart';

/// Reads and writes reports. The only class in the reports feature that
/// talks to Firestore, so screens and providers never see Firestore types.
class ReportRepository {
  ReportRepository(this._db);

  final FirebaseFirestore _db;

  /// Ticket numbers start after this, so the first report is #1001.
  static const firstTicketNumber = 1001;

  /// How many reports Browse loads. Plenty for one campus; search and
  /// filters then run on the device (Firestore has no full-text search).
  static const browseLimit = 200;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  DocumentReference<Map<String, dynamic>> get _counter =>
      _db.doc('counters/reports');

  /// Every report on campus, newest first.
  Stream<List<Report>> watchAll() => _reports
      .orderBy('createdAt', descending: true)
      .limit(browseLimit)
      .snapshots()
      .map(_toReports);

  /// The private records linking a student to their anonymous reports.
  /// Only that student can read them (see `firestore.rules`).
  CollectionReference<Map<String, dynamic>> _ownedAnonymous(String uid) =>
      _db.collection('users').doc(uid).collection('reports');

  /// One student's named reports, newest first. Needs the
  /// `reporterId + createdAt` index in `firestore.indexes.json`.
  Stream<List<Report>> watchNamedBy(String uid) => _reports
      .where('reporterId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_toReports);

  /// Ids of the reports a student sent anonymously.
  Stream<Set<String>> watchAnonymousIds(String uid) =>
      _ownedAnonymous(uid)
          .snapshots()
          .map((q) => {for (final d in q.docs) d.id});

  /// The given reports, live. Firestore's `whereIn` takes at most 30 ids,
  /// so longer lists are split into several queries and joined.
  Stream<List<Report>> watchByIds(Iterable<String> ids) {
    final all = ids.toList();
    if (all.isEmpty) return Stream.value(const []);
    return combineLatestLists([
      for (var i = 0; i < all.length; i += 30)
        _reports
            .where(
              FieldPath.documentId,
              whereIn: all.sublist(i, (i + 30).clamp(0, all.length)),
            )
            .snapshots()
            .map(_toReports),
    ]);
  }

  /// A single report, live. Emits null if it doesn't exist (or was deleted).
  Stream<Report?> watchReport(String id) => _reports
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? Report.fromJson(s.id, s.data()!) : null);

  /// The staff updates on a report, oldest first (timeline order).
  Stream<List<ReportUpdate>> watchUpdates(String reportId) => _reports
      .doc(reportId)
      .collection('updates')
      .orderBy('createdAt')
      .snapshots()
      .map(
        (q) => [for (final d in q.docs) ReportUpdate.fromJson(d.id, d.data())],
      );

  /// The photos attached to a report, in the order they were added. Read
  /// once rather than streamed: photos never change after submission, and
  /// Firestore's cache means opening the report again costs nothing.
  Future<List<Uint8List>> fetchPhotos(String reportId) async {
    final query = await _reports
        .doc(reportId)
        .collection('photos')
        .orderBy('index')
        .get();
    return [
      for (final d in query.docs)
        if (d.data()['data'] case final Blob blob) blob.bytes,
    ];
  }

  /// The photo staff attached when they resolved the report, or null.
  Future<Uint8List?> fetchAfterPhoto(String reportId) async {
    final doc = await _reports
        .doc(reportId)
        .collection('photos')
        .doc('after')
        .get();
    return switch (doc.data()?['data']) {
      final Blob blob => blob.bytes,
      _ => null,
    };
  }

  /// Creates a report and returns its id.
  ///
  /// Everything happens in one transaction: the ticket counter goes up by
  /// one, the report is written with that number, and each photo is written
  /// to its own document. Either all of it is saved or none of it is, so
  /// there are never two reports with the same number or a report with
  /// missing photos. The security rules check the same things on the server.
  Future<String> createReport({
    required ReportDraft draft,
    required AppUser reporter,
    List<Uint8List> photos = const [],
  }) async {
    if (photos.length > AppConfig.maxPhotos) {
      throw const UserFacingException(
        'You can attach up to ${AppConfig.maxPhotos} photos.',
      );
    }
    if (photos.any((p) => p.lengthInBytes > AppConfig.photoMaxBytes)) {
      throw const UserFacingException(
        'One of the photos is too large. Try a different one.',
      );
    }

    final reportRef = _reports.doc();
    try {
      await _db.runTransaction((tx) async {
        final counter = await tx.get(_counter);
        final last = (counter.data()?['last'] as num?)?.toInt();
        final ticketNumber = last == null ? firstTicketNumber : last + 1;

        final report = Report(
          id: reportRef.id,
          ticketNumber: ticketNumber,
          title: draft.title.trim(),
          description: draft.description.trim(),
          category: draft.category,
          location: draft.location.trim(),
          urgency: draft.urgency,
          status: ReportStatus.submitted,
          reporterId: draft.anonymous ? null : reporter.uid,
          reporterName: draft.anonymous ? null : reporter.name,
          anonymous: draft.anonymous,
          photoCount: photos.length,
        );

        tx.set(_counter, {'last': ticketNumber});
        tx.set(reportRef, {
          ...report.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (draft.anonymous) {
          // The only link between the student and this report, readable by
          // nobody else.
          tx.set(_ownedAnonymous(reporter.uid).doc(reportRef.id), {
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        for (var i = 0; i < photos.length; i++) {
          tx.set(reportRef.collection('photos').doc('$i'), {
            'index': i,
            'data': Blob(photos[i]),
          });
        }
      });
    } on FirebaseException catch (e) {
      // The real reason, for the developer. Debug builds also show the code
      // under the form so a failed save can be traced without a debugger.
      debugPrint('createReport failed: ${e.code}: ${e.message}');
      final message = _messageFor(e.code);
      throw UserFacingException(kDebugMode ? '$message (${e.code})' : message);
    }
    return reportRef.id;
  }

  /// Emits every stream's latest list joined into one, once each stream has
  /// emitted at least once. Errors from any stream are passed on.
  static Stream<List<T>> combineLatestLists<T>(List<Stream<List<T>>> streams) {
    if (streams.length == 1) return streams.single;
    final latest = List<List<T>?>.filled(streams.length, null);
    final subs = <StreamSubscription<List<T>>>[];
    late final StreamController<List<T>> controller;
    controller = StreamController<List<T>>(
      onListen: () {
        for (var i = 0; i < streams.length; i++) {
          subs.add(
            streams[i].listen((value) {
              latest[i] = value;
              if (latest.every((l) => l != null)) {
                controller.add([for (final l in latest) ...l!]);
              }
            }, onError: controller.addError),
          );
        }
      },
      onCancel: () => Future.wait([for (final s in subs) s.cancel()]),
    );
    return controller.stream;
  }

  static List<Report> _toReports(QuerySnapshot<Map<String, dynamic>> q) => [
    for (final d in q.docs) Report.fromJson(d.id, d.data()),
  ];

  static String _messageFor(String code) => switch (code) {
    'permission-denied' =>
      "Your report couldn't be saved. Check every field and try again.",
    'unavailable' ||
    'deadline-exceeded' => 'No connection. Check your internet and try again.',
    'aborted' => 'Lots of reports are coming in. Please try again.',
    _ => "Your report couldn't be sent. Please try again.",
  };
}
