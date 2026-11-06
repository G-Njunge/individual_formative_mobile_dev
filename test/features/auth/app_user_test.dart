import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/features/auth/data/app_user.dart';

void main() {
  test('student round trip omits staff-only fields', () {
    const user = AppUser(
      uid: 'u1',
      name: 'Amani Mugisha',
      email: 'a.mugisha@alustudent.com',
      role: UserRole.student,
    );
    final json = user.toJson();
    expect(json, {
      'name': 'Amani Mugisha',
      'email': 'a.mugisha@alustudent.com',
      'role': 'student',
    });
    final back = AppUser.fromJson('u1', json);
    expect(back.role, UserRole.student);
    expect(back.firstName, 'Amani');
    expect(back.canUseStaffFeatures, isFalse);
  });

  test('staff fields and timestamps are read', () {
    final created = DateTime(2026, 10, 1, 9);
    final user = AppUser.fromJson('s1', {
      'name': 'Jean Habimana',
      'email': 'j.habimana@alueducation.com',
      'role': 'staff',
      'staffId': 'FAC-0231',
      'team': 'Plumbing',
      'approved': true,
      'createdAt': Timestamp.fromDate(created),
    });
    expect(user.isStaff, isTrue);
    expect(user.canUseStaffFeatures, isTrue);
    expect(user.team, 'Plumbing');
    expect(user.createdAt, created);
    expect(user.toJson()['approved'], isTrue);
  });

  test('missing or unknown values fall back safely', () {
    final user = AppUser.fromJson('x', {'role': 'admin'});
    expect(user.role, UserRole.student);
    expect(user.approved, isFalse);
    expect(user.createdAt, isNull);
  });

  test('roles know their email domains', () {
    expect(UserRole.student.emailHint, 'you@alustudent.com');
    expect(UserRole.staff.allowedEmailDomains, ['alueducation.com']);
  });
}
