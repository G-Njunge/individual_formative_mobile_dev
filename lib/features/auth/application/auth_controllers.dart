import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_user.dart';
import '../data/auth_repository.dart';
import 'auth_providers.dart';

/// Each form's submit action lives in a small controller. The screen watches
/// its `AsyncValue` for the loading spinner and the error message; the
/// controller holds no widget code and can be tested on its own.
class SignInController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authBusyProvider.notifier)
          .during(
            () => ref
                .read(authRepositoryProvider)
                .signIn(email: email, password: password, expectedRole: role),
          ),
    );
  }
}

final signInControllerProvider =
    NotifierProvider.autoDispose<SignInController, AsyncValue<void>>(
      SignInController.new,
    );

class SignUpController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? staffId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authBusyProvider.notifier)
          .during(
            () => ref
                .read(authRepositoryProvider)
                .signUp(
                  name: name,
                  email: email,
                  password: password,
                  role: role,
                  staffId: staffId,
                ),
          ),
    );
  }
}

final signUpControllerProvider =
    NotifierProvider.autoDispose<SignUpController, AsyncValue<void>>(
      SignUpController.new,
    );

class PasswordResetController extends Notifier<AsyncValue<bool>> {
  /// `true` once the email has been sent.
  @override
  AsyncValue<bool> build() => const AsyncData(false);

  Future<void> send(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      return true;
    });
  }
}

final passwordResetControllerProvider =
    NotifierProvider.autoDispose<PasswordResetController, AsyncValue<bool>>(
      PasswordResetController.new,
    );

/// Drives the "Check your email" screen: checking, resending with a
/// cooldown, and removing the account.
class VerifyEmailController extends Notifier<AsyncValue<void>> {
  static const resendCooldown = Duration(seconds: 60);

  DateTime? _lastSent;

  @override
  AsyncValue<void> build() {
    // The sign-up flow sends the first email, so the cooldown starts now.
    _lastSent = DateTime.now();
    return const AsyncData(null);
  }

  Duration get resendWait {
    final last = _lastSent;
    if (last == null) return Duration.zero;
    final left = resendCooldown - DateTime.now().difference(last);
    return left.isNegative ? Duration.zero : left;
  }

  /// Returns true once the email is verified. The router then moves on by
  /// itself, because the session status changes.
  Future<bool> check({bool quiet = false}) async {
    if (!quiet) state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).refreshVerification(),
    );
    if (!quiet || result.hasError) state = result;
    return result.value ?? false;
  }

  Future<void> resend() async {
    if (resendWait > Duration.zero) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).sendVerificationEmail(),
    );
    if (!state.hasError) _lastSent = DateTime.now();
  }

  /// Deletes the account if it is past the 24-hour window. Returns true if
  /// it was removed.
  Future<bool> removeIfExpired() async {
    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentUser;
    if (user == null || !AuthRepository.isVerificationExpired(user)) {
      return false;
    }
    // Set the message first: deleting signs the user out, and the router
    // opens Sign in straight away.
    ref
        .read(flashMessageProvider.notifier)
        .show(
          "Your account wasn't verified within 24 hours, so it was "
          'removed. Please create it again.',
        );
    await repo.deleteUnverifiedAccount();
    return true;
  }

  Future<void> useDifferentEmail() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).deleteUnverifiedAccount(),
    );
  }
}

final verifyEmailControllerProvider =
    NotifierProvider.autoDispose<VerifyEmailController, AsyncValue<void>>(
      VerifyEmailController.new,
    );
