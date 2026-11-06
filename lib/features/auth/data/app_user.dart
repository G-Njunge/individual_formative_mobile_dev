import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/app_config.dart';

enum UserRole {
  student('student', 'Student', 'Sign in'),
  staff('staff', 'Campus staff', 'Sign in to staff dashboard');

  const UserRole(this.value, this.label, this.signInLabel);

  /// Stored in Firestore.
  final String value;
  final String label;
  final String signInLabel;

  List<String> get allowedEmailDomains => switch (this) {
    UserRole.student => AppConfig.studentEmailDomains,
    UserRole.staff => AppConfig.staffEmailDomains,
  };

  String get emailHint => 'you@${allowedEmailDomains.first}';

  static UserRole fromValue(String? value) =>
      value == 'staff' ? UserRole.staff : UserRole.student;
}

/// The profile stored at `users/{uid}`. Firebase Auth holds the login; this
/// document holds what the app needs to know about the person.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.staffId,
    this.team,
    this.approved = false,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;

  /// Staff only. Checked by the facilities office before approval.
  final String? staffId;

  /// Staff only, set by an admin on approval (e.g. "Plumbing").
  final String? team;

  /// Staff only. Staff features stay locked until an admin sets this to true.
  final bool approved;

  /// Null for a moment after creation, until the server timestamp arrives.
  final DateTime? createdAt;

  bool get isStaff => role == UserRole.staff;
  bool get canUseStaffFeatures => isStaff && approved;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  factory AppUser.fromJson(String uid, Map<String, dynamic> json) {
    final role = UserRole.fromValue(json['role'] as String?);
    return AppUser(
      uid: uid,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: role,
      staffId: json['staffId'] as String?,
      team: json['team'] as String?,
      approved: (json['approved'] as bool?) ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Fields written when the profile is created. `createdAt` is added by the
  /// repository as a server timestamp so phones with wrong clocks can't lie.
  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'role': role.value,
    if (isStaff) 'staffId': staffId,
    if (isStaff) 'approved': approved,
    if (team != null) 'team': team,
  };
}
