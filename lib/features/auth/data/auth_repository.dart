import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/user_facing_exception.dart';
import 'app_user.dart';

/// Everything to do with accounts: sign in and up, email verification,
/// password reset and the profile document at `users/{uid}`.
///
/// It is the only class that talks to Firebase Auth, so screens and providers
/// never handle Firebase types or error codes directly.
class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Accounts must verify their email within this window or they are removed.
  static const verificationWindow = Duration(hours: 24);

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  User? get currentUser => _auth.currentUser;

  /// Emits on sign in, sign out and profile changes (including email
  /// verification after [refreshVerification]).
  Stream<User?> userChanges() => _auth.userChanges();

  Stream<AppUser?> watchProfile(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? AppUser.fromJson(s.id, s.data()!) : null);

  /// Signs in and checks the account matches the role picked on the toggle,
  /// so a student can't land in the staff flow by mistake (and vice versa).
  Future<void> signIn({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    final credential = await _guard(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
    final user = credential.user!;

    if (await deleteIfVerificationExpired(user)) {
      throw const UserFacingException(
        "This account wasn't verified within 24 hours, so it was removed. "
        'Please create it again.',
      );
    }

    final snapshot = await _users.doc(user.uid).get();
    // No profile: the router shows the "account problem" page.
    if (!snapshot.exists) return;
    final role = UserRole.fromValue(snapshot.data()!['role'] as String?);
    if (role != expectedRole) {
      await _auth.signOut();
      throw UserFacingException(
        'This is a ${role == UserRole.staff ? 'staff' : 'student'} account. '
        'Choose ${role.label} above to sign in.',
      );
    }
  }

  /// Creates the login, writes the profile and sends the verification email.
  /// If the profile can't be written the login is deleted again, so we never
  /// leave behind an account without a profile.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? staffId,
  }) async {
    final credential = await _guard(
      () => _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
    final user = credential.user!;
    final profile = AppUser(
      uid: user.uid,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      role: role,
      staffId: role == UserRole.staff ? staffId?.trim().toUpperCase() : null,
    );

    try {
      await _users.doc(user.uid).set({
        ...profile.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await user.updateDisplayName(profile.name);
    } catch (_) {
      await user.delete();
      throw const UserFacingException(
        "We couldn't finish creating your account. Please try again.",
      );
    }

    // Not fatal if this fails: the verify screen has a "Resend" button.
    try {
      await user.sendEmailVerification();
    } catch (_) {}
  }

  Future<void> sendVerificationEmail() =>
      _guard(() => _auth.currentUser!.sendEmailVerification());

  /// Reloads the account from the server. The ID token is refreshed too, so
  /// security rules see `email_verified == true` straight away.
  Future<bool> refreshVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await _guard(user.reload);
    final fresh = _auth.currentUser!;
    if (fresh.emailVerified) await fresh.getIdToken(true);
    return fresh.emailVerified;
  }

  static bool isVerificationExpired(User user, {DateTime? now}) {
    final created = user.metadata.creationTime;
    if (user.emailVerified || created == null) return false;
    return (now ?? DateTime.now()).difference(created) > verificationWindow;
  }

  /// Removes an account that missed the 24-hour verification window.
  /// Returns true if it was removed.
  Future<bool> deleteIfVerificationExpired(User user, {DateTime? now}) async {
    if (!isVerificationExpired(user, now: now)) return false;
    await deleteUnverifiedAccount();
    return true;
  }

  /// Deletes the signed-in account and its profile. Only used for accounts
  /// that never verified their email ("Use a different email", or expiry).
  Future<void> deleteUnverifiedAccount() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    try {
      await _users.doc(user.uid).delete();
    } catch (_) {
      // The admin clean-up script removes any profile left behind.
    }
    await _guard(user.delete);
  }

  /// Firebase does not say whether the email has an account (that would let
  /// anyone check who is registered), so the screen words its message the
  /// same either way.
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  Future<void> signOut() => _auth.signOut();

  /// Whether the login token carries the `staff` flag the security rules
  /// check. `npm run approve` sets it, but a phone keeps its old token for
  /// up to an hour, so a missing flag triggers one refresh before giving up.
  Future<bool> hasStaffAccess() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      if ((await user.getIdTokenResult()).claims?['staff'] == true) {
        return true;
      }
      return (await user.getIdTokenResult(true)).claims?['staff'] == true;
    } on FirebaseAuthException {
      return false;
    }
  }

  /// Runs a Firebase Auth call and turns its error codes into messages
  /// people can act on.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseAuthException catch (e) {
      throw UserFacingException(
        e.code == 'password-does-not-meet-requirements'
            ? messageForPasswordPolicy(e.message)
            : messageForAuthError(e.code),
      );
    }
  }

  /// The password policy in the Firebase console can be stricter than the
  /// app's checklist. Firebase lists what is missing in its message, e.g.
  /// "Missing password requirements: [Password must contain a numeric
  /// character]", so that list is passed on.
  static String messageForPasswordPolicy(String? firebaseMessage) {
    final missing = RegExp(r'\[(.*)\]')
        .firstMatch(firebaseMessage ?? '')
        ?.group(1)
        ?.trim();
    if (missing == null || missing.isEmpty) {
      return "This password doesn't meet the campus password rules. "
          'Try a longer one with a mix of letters, numbers and symbols.';
    }
    return "This password doesn't meet the campus password rules: $missing.";
  }

  static String messageForAuthError(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'INVALID_LOGIN_CREDENTIALS' => 'That email and password do not match.',
    'email-already-in-use' =>
      'An account with this email already exists. Sign in, or reset your '
          'password.',
    'invalid-email' => 'Enter a valid email address.',
    'weak-password' => 'Choose a stronger password.',
    'user-disabled' =>
      'This account has been disabled. Contact the facilities office.',
    'too-many-requests' =>
      'Too many attempts. Wait a few minutes and try again.',
    'network-request-failed' =>
      'No connection. Check your internet and try again.',
    'requires-recent-login' => 'Please sign in again and retry.',
    _ => 'Something went wrong. Please try again.',
  };
}
