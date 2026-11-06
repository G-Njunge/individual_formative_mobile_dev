import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/app_user.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

/// The Firebase login, or null when signed out.
final authUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);

/// The signed-in person's profile document, live.
final currentProfileProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(authUserProvider.select((u) => u.value?.uid));
  if (uid == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfile(uid);
});

enum SessionStatus {
  /// Still finding out who is signed in.
  loading,
  signedOut,

  /// Signed in, but the email link has not been clicked yet.
  needsVerification,

  /// Signed in and verified, but there is no profile document.
  missingProfile,

  /// Staff account the facilities office has not approved yet.
  awaitingApproval,
  student,
  staff,
}

class Session {
  const Session(this.status, {this.user, this.profile});

  final SessionStatus status;
  final User? user;
  final AppUser? profile;
}

/// Combines the login and the profile into one status. The router redirects
/// on this, so every screen can assume the right kind of user is signed in.
final sessionProvider = Provider<Session>((ref) {
  final auth = ref.watch(authUserProvider);
  final user = auth.value;
  if (auth.isLoading && user == null) {
    return const Session(SessionStatus.loading);
  }
  if (user == null) return const Session(SessionStatus.signedOut);
  if (!user.emailVerified) {
    return Session(SessionStatus.needsVerification, user: user);
  }

  final profileValue = ref.watch(currentProfileProvider);
  final profile = profileValue.value;
  if (profile == null) {
    return Session(
      profileValue.isLoading
          ? SessionStatus.loading
          : SessionStatus.missingProfile,
      user: user,
    );
  }
  final status = switch (profile.role) {
    UserRole.student => SessionStatus.student,
    UserRole.staff when profile.approved => SessionStatus.staff,
    UserRole.staff => SessionStatus.awaitingApproval,
  };
  return Session(status, user: user, profile: profile);
});

/// True while sign in or sign up is running. Firebase reports "signed in"
/// before our own checks (role, profile) finish, so the router waits for this
/// to clear instead of jumping to Home and back.
class AuthBusy extends Notifier<bool> {
  @override
  bool build() => false;

  Future<T> during<T>(Future<T> Function() action) async {
    state = true;
    try {
      return await action();
    } finally {
      state = false;
    }
  }
}

final authBusyProvider = NotifierProvider<AuthBusy, bool>(AuthBusy.new);

/// A one-off message to show on the next screen (e.g. "your unverified
/// account was removed"), since the screen that caused it is gone by then.
class FlashMessage extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) => state = message;

  String? take() {
    final message = state;
    state = null;
    return message;
  }
}

final flashMessageProvider = NotifierProvider<FlashMessage, String?>(
  FlashMessage.new,
);
