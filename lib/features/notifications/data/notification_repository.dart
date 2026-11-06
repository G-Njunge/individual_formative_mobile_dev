import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/user_facing_exception.dart';
import '../../auth/data/app_user.dart';
import 'app_notification.dart';

/// The signed-in person's notifications and campus announcements.
class NotificationRepository {
  NotificationRepository(this._db);

  final FirebaseFirestore _db;

  /// How many notifications the screen loads. Older ones stay in Firestore.
  static const inboxLimit = 50;

  static const maxAnnouncementTitle = 80;
  static const maxAnnouncementBody = 300;

  CollectionReference<Map<String, dynamic>> _inbox(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _db.collection('announcements');

  /// Newest first. Only the owner can read them (see `firestore.rules`).
  Stream<List<AppNotification>> watchInbox(String uid) => _inbox(uid)
      .orderBy('createdAt', descending: true)
      .limit(inboxLimit)
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs) AppNotification.fromJson(d.id, d.data()),
        ],
      );

  /// Marks the given stored notifications as read, in one batch.
  Future<void> markRead(String uid, Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final batch = _db.batch();
    for (final id in list) {
      batch.update(_inbox(uid).doc(id), {'read': true});
    }
    await _guard(batch.commit);
  }

  /// The most recent announcement, or null.
  Stream<Announcement?> watchLatestAnnouncement() => _announcements
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map(
        (q) => q.docs.isEmpty
            ? null
            : Announcement.fromJson(q.docs.single.id, q.docs.single.data()),
      );

  /// Staff only (checked by the rules).
  Future<void> postAnnouncement({
    required String title,
    required String body,
    required AppUser by,
  }) async {
    final t = title.trim(), b = body.trim();
    if (t.length < 5) {
      throw const UserFacingException('Give the announcement a short title.');
    }
    if (t.length > maxAnnouncementTitle || b.length > maxAnnouncementBody) {
      throw const UserFacingException('The announcement is too long.');
    }
    await _guard(
      () => _announcements.add({
        'title': t,
        'body': b,
        'byName': by.name,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (e) {
      debugPrint('Notifications call failed: ${e.code}: ${e.message}');
      final message = switch (e.code) {
        'unavailable' || 'deadline-exceeded' =>
          'No connection. Check your internet and try again.',
        'permission-denied' =>
          "That wasn't allowed. If you are staff, ask the facilities office "
              'to approve your account again.',
        _ => 'Something went wrong. Please try again.',
      };
      throw UserFacingException(kDebugMode ? '$message (${e.code})' : message);
    }
  }
}
