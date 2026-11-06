import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/user_facing_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/app_user.dart';
import '../../reports/data/report.dart';
import '../data/staff_repository.dart';
import '../data/staff_update.dart';

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => StaffRepository(ref.watch(firestoreProvider)),
);

/// Approved staff, for "Assigned to".
final staffMembersProvider = StreamProvider.autoDispose<List<AppUser>>(
  (ref) => ref.watch(staffRepositoryProvider).watchStaffMembers(),
);

/// Checks the login token carries the staff flag (see `approve-staff.js`).
/// A provider so tests can replace it.
final staffAccessCheckProvider = Provider<Future<bool> Function()>(
  (ref) => ref.watch(authRepositoryProvider).hasStaffAccess,
);

/// Saves "Review and update" and "Duplicate". Its state is the save in
/// progress, or the error from the last attempt.
class StaffUpdateController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns true once saved.
  Future<bool> save(Report report, StaffUpdateDraft draft) => _run(
    (by) => ref
        .read(staffRepositoryProvider)
        .saveUpdate(report: report, draft: draft, by: by),
  );

  /// Returns true once saved.
  Future<bool> markDuplicate(Report report, int originalTicket) => _run(
    (by) => ref
        .read(staffRepositoryProvider)
        .markDuplicate(report: report, originalTicket: originalTicket, by: by),
  );

  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }

  Future<bool> _run(Future<void> Function(AppUser by) action) async {
    if (state.isLoading) return false;
    final by = ref.read(sessionProvider).profile;
    if (by == null) return false;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      if (!await ref.read(staffAccessCheckProvider)()) {
        throw const UserFacingException(
          "Your staff access isn't switched on yet. Ask the facilities "
          'office to approve your account again, then sign out and back in.',
        );
      }
      await action(by);
    });
    if (!ref.mounted) return !result.hasError;
    state = result;
    return !result.hasError;
  }
}

final staffUpdateControllerProvider =
    NotifierProvider.autoDispose<StaffUpdateController, AsyncValue<void>>(
      StaffUpdateController.new,
    );
