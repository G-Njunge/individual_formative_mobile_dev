import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report.dart';
import 'report_filters.dart';
import 'report_providers.dart';

/// Whether the signed-in student backs this report.
final isSupporterProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  reportId,
) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(false);
  return ref.watch(reportRepositoryProvider).watchIsSupporter(reportId, uid);
});

/// Ids of the reports the signed-in student backs.
final followingIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const {});
  return ref.watch(reportRepositoryProvider).watchFollowingIds(uid);
});

/// "Followed reports" on Profile: the reports the student backs, newest
/// first.
final followedReportsProvider = StreamProvider.autoDispose<List<Report>>((ref) {
  final ids = ref.watch(followingIdsProvider).value;
  if (ids == null) return const Stream.empty();
  return ref
      .watch(reportRepositoryProvider)
      .watchByIds(ids)
      .map((r) => filterReports(r));
});

/// Me too, "Yes, fixed" and "Reopen" on one report. Its state is the action
/// in progress, or the error from the last one.
class ReportActionsController extends Notifier<AsyncValue<void>> {
  ReportActionsController(this.reportId);

  final String reportId;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> setSupport(bool support) {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return Future.value(false);
    return _run(
      () => ref
          .read(reportRepositoryProvider)
          .setSupport(reportId: reportId, uid: uid, support: support),
    );
  }

  Future<bool> confirmFixed() =>
      _run(() => ref.read(reportRepositoryProvider).confirmFixed(reportId));

  Future<bool> reopen(String reason) => _run(
    () => ref.read(reportRepositoryProvider).reopen(reportId, reason: reason),
  );

  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

final reportActionsProvider = NotifierProvider.autoDispose
    .family<ReportActionsController, AsyncValue<void>, String>(
      ReportActionsController.new,
    );
