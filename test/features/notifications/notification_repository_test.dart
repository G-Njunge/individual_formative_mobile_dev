import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/errors/user_facing_exception.dart';
import 'package:individual_formative/core/models/report_enums.dart';
import 'package:individual_formative/features/auth/data/app_user.dart';
import 'package:individual_formative/features/notifications/data/app_notification.dart';
import 'package:individual_formative/features/notifications/data/notification_repository.dart';

const jean = AppUser(
  uid: 's1',
  name: 'Jean Habimana',
  email: 'jean.h@alueducation.com',
  role: UserRole.staff,
  approved: true,
);

void main() {
  late FakeFirebaseFirestore db;
  late NotificationRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = NotificationRepository(db);
  });

  test('reads the inbox newest first and marks rows read', () async {
    for (final (id, day) in [('a', 1), ('b', 3), ('c', 2)]) {
      await db.doc('users/u1/notifications/$id').set({
        'type': id == 'c' ? 'note' : 'status',
        'reportId': 'r1',
        'ticketNumber': 1042,
        'reportTitle': 'Leaking tap',
        'status': 'in_progress',
        'note': id == 'c' ? 'Parts ordered' : null,
        'read': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, day)),
      });
    }
    final inbox = await repo.watchInbox('u1').first;
    expect([for (final n in inbox) n.id], ['b', 'c', 'a']);
    expect(inbox[1].kind, NotificationKind.note);
    expect(inbox[1].note, 'Parts ordered');
    expect(inbox.first.status, ReportStatus.inProgress);

    await repo.markRead('u1', ['a', 'b']);
    final after = await repo.watchInbox('u1').first;
    expect(
      {for (final n in after) n.id: n.read},
      {'b': true, 'c': false, 'a': true},
    );
  });

  test('posts an announcement and reads the latest one', () async {
    expect(await repo.watchLatestAnnouncement().first, isNull);
    await repo.postAnnouncement(
      title: '  Planned water cut in Hostel A ',
      body: 'Saturday, 9:00 to 12:00.',
      by: jean,
    );
    final latest = await repo.watchLatestAnnouncement().first;
    expect(latest?.title, 'Planned water cut in Hostel A');
    expect(latest?.byName, 'Jean Habimana');
  });

  test('refuses an announcement without a proper title', () {
    expect(
      () => repo.postAnnouncement(title: 'Hi', body: '', by: jean),
      throwsA(isA<UserFacingException>()),
    );
  });
}
