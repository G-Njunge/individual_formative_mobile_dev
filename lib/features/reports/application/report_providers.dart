import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/models/report_enums.dart';
import '../../auth/application/auth_providers.dart';
import '../data/photo_picker.dart';
import '../data/report.dart';
import '../data/report_repository.dart';
import 'report_filters.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(firestoreProvider)),
);

final photoPickerProvider = Provider<PhotoPicker>((ref) => PhotoPicker());

/// Every report on campus, live.
final allReportsProvider = StreamProvider.autoDispose<List<Report>>(
  (ref) => ref.watch(reportRepositoryProvider).watchAll(),
);

final _uidProvider = Provider.autoDispose<String?>(
  (ref) => ref.watch(authUserProvider.select((u) => u.value?.uid)),
);

/// The signed-in student's named reports (they carry `reporterId`).
final myNamedReportsProvider = StreamProvider.autoDispose<List<Report>>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(reportRepositoryProvider).watchNamedBy(uid);
});

/// Ids of the reports the signed-in student sent anonymously, read from
/// their private records.
final myAnonymousIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid == null) return Stream.value(const {});
  return ref.watch(reportRepositoryProvider).watchAnonymousIds(uid);
});

/// The anonymous reports themselves. When the id list changes, Riverpod
/// drops the old query and opens a new one.
final _myAnonymousReportsProvider = StreamProvider.autoDispose<List<Report>>((
  ref,
) {
  final ids = ref.watch(myAnonymousIdsProvider).value;
  if (ids == null) return const Stream.empty();
  return ref.watch(reportRepositoryProvider).watchByIds(ids);
});

/// The signed-in student's own reports, named and anonymous, newest first.
/// Feeds Home and "My reports".
final myReportsProvider = Provider.autoDispose<AsyncValue<List<Report>>>((ref) {
  final named = ref.watch(myNamedReportsProvider);
  final anonymous = ref.watch(_myAnonymousReportsProvider);
  return switch ((named, anonymous)) {
    (AsyncData(value: final a), AsyncData(value: final b)) => AsyncData(
      filterReports([...a, ...b]),
    ),
    (AsyncError(:final error, :final stackTrace), _) ||
    (
      _,
      AsyncError(:final error, :final stackTrace),
    ) => AsyncError(error, stackTrace),
    _ => const AsyncLoading(),
  };
});

/// Re-opens the queries behind [myReportsProvider] (the "Try again" button).
void retryMyReports(WidgetRef ref) {
  ref.invalidate(myNamedReportsProvider);
  ref.invalidate(myAnonymousIdsProvider);
}

/// Whether the signed-in person sent this report, named or anonymously.
/// Keyed by `(report id, reporterId)`: a record compares by value, so the
/// same report always maps to the same provider.
final isMyReportProvider = Provider.autoDispose
    .family<bool, ({String id, String? reporterId})>((ref, key) {
      final uid = ref.watch(_uidProvider);
      if (uid == null) return false;
      if (key.reporterId == uid) return true;
      return ref.watch(myAnonymousIdsProvider).value?.contains(key.id) ?? false;
    });

final reportProvider = StreamProvider.autoDispose.family<Report?, String>(
  (ref, id) => ref.watch(reportRepositoryProvider).watchReport(id),
);

final reportUpdatesProvider = StreamProvider.autoDispose
    .family<List<ReportUpdate>, String>(
      (ref, id) => ref.watch(reportRepositoryProvider).watchUpdates(id),
    );

final reportPhotosProvider = FutureProvider.autoDispose
    .family<List<Uint8List>, String>(
      (ref, id) => ref.watch(reportRepositoryProvider).fetchPhotos(id),
    );

final reportAfterPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>(
      (ref, id) => ref.watch(reportRepositoryProvider).fetchAfterPhoto(id),
    );

/// The progress timeline for one report, rebuilt whenever the report or
/// its updates change.
final reportTimelineProvider = Provider.autoDispose
    .family<AsyncValue<List<TimelineEntry>>, String>((ref, id) {
      final report = ref.watch(reportProvider(id));
      final updates = ref.watch(reportUpdatesProvider(id));
      return switch ((report, updates)) {
        (AsyncData(value: final r?), AsyncData(value: final u)) => AsyncData(
          buildTimeline(r, u),
        ),
        (AsyncError(:final error, :final stackTrace), _) ||
        (
          _,
          AsyncError(:final error, :final stackTrace),
        ) => AsyncError(error, stackTrace),
        (AsyncData(value: null), _) => const AsyncData([]),
        _ => const AsyncLoading(),
      };
    });

// ---------- Browse ----------

enum BrowseScope { all, mine }

class BrowseFilters {
  const BrowseFilters({
    this.scope = BrowseScope.all,
    this.query = '',
    this.status,
    this.sort = ReportSort.newest,
  });

  final BrowseScope scope;
  final String query;

  /// Null means every status ("All").
  final ReportStatus? status;
  final ReportSort sort;

  BrowseFilters copyWith({
    BrowseScope? scope,
    String? query,
    ReportStatus? Function()? status,
    ReportSort? sort,
  }) => BrowseFilters(
    scope: scope ?? this.scope,
    query: query ?? this.query,
    status: status == null ? this.status : status(),
    sort: sort ?? this.sort,
  );
}

/// Browse's search, chips, toggle and sort. Kept in a provider (not the
/// screen) so Home can open Browse with a search or scope already set, and
/// so switching tabs doesn't lose them.
class BrowseFiltersController extends Notifier<BrowseFilters> {
  @override
  BrowseFilters build() => const BrowseFilters();

  void setScope(BrowseScope scope) => state = state.copyWith(scope: scope);
  void setQuery(String query) => state = state.copyWith(query: query);
  void setStatus(ReportStatus? status) =>
      state = state.copyWith(status: () => status);
  void cycleSort() => state = state.copyWith(sort: state.sort.next);

  /// Used by Home: "View all" opens My reports, a search opens All reports.
  void open({required BrowseScope scope, String query = ''}) =>
      state = BrowseFilters(scope: scope, query: query, sort: state.sort);
}

final browseFiltersProvider =
    NotifierProvider<BrowseFiltersController, BrowseFilters>(
      BrowseFiltersController.new,
    );

/// The Browse list after scope, search, status and sort are applied.
final browseResultsProvider = Provider.autoDispose<AsyncValue<List<Report>>>((
  ref,
) {
  final filters = ref.watch(browseFiltersProvider);
  final source = ref.watch(
    filters.scope == BrowseScope.all ? allReportsProvider : myReportsProvider,
  );
  return source.whenData(
    (reports) => filterReports(
      reports,
      query: filters.query,
      status: filters.status,
      sort: filters.sort,
    ),
  );
});
