import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/user_facing_exception.dart';
import '../../../core/models/report_enums.dart';
import '../../auth/application/auth_providers.dart';
import '../data/report.dart';
import 'report_providers.dart';

/// Everything on the New report form that isn't a text field. The text
/// fields stay in the screen's controllers, which Flutter forms expect.
class NewReportState {
  const NewReportState({
    this.photos = const [],
    this.category,
    this.urgency = Urgency.medium,
    this.anonymous = false,
    this.showCategoryError = false,
    this.photoError,
    this.submission = const AsyncData(null),
  });

  final List<Uint8List> photos;

  /// Null until the student picks one; it is required.
  final ReportCategory? category;
  final Urgency urgency;
  final bool anonymous;

  /// Set after a submit attempt with no category, so the grid shows an error.
  final bool showCategoryError;

  /// Why the last photo couldn't be added, if it couldn't.
  final String? photoError;

  /// The new report's id once it is saved.
  final AsyncValue<String?> submission;

  bool get canAddPhoto => photos.length < AppConfig.maxPhotos;

  NewReportState copyWith({
    List<Uint8List>? photos,
    ReportCategory? category,
    Urgency? urgency,
    bool? anonymous,
    bool? showCategoryError,
    String? Function()? photoError,
    AsyncValue<String?>? submission,
  }) => NewReportState(
    photos: photos ?? this.photos,
    category: category ?? this.category,
    urgency: urgency ?? this.urgency,
    anonymous: anonymous ?? this.anonymous,
    showCategoryError: showCategoryError ?? this.showCategoryError,
    photoError: photoError == null ? this.photoError : photoError(),
    submission: submission ?? this.submission,
  );
}

class NewReportController extends Notifier<NewReportState> {
  @override
  NewReportState build() => const NewReportState();

  Future<void> addPhoto() async {
    if (!state.canAddPhoto) return;
    try {
      final bytes = await ref.read(photoPickerProvider).pick();
      if (bytes == null || !ref.mounted) return;
      state = state.copyWith(
        photos: [...state.photos, bytes],
        photoError: () => null,
      );
    } on UserFacingException catch (e) {
      if (ref.mounted) state = state.copyWith(photoError: () => e.message);
    }
  }

  void removePhoto(int index) {
    final photos = [...state.photos]..removeAt(index);
    state = state.copyWith(photos: photos, photoError: () => null);
  }

  void setCategory(ReportCategory category) =>
      state = state.copyWith(category: category, showCategoryError: false);

  void setUrgency(Urgency urgency) => state = state.copyWith(urgency: urgency);

  void setAnonymous(bool anonymous) =>
      state = state.copyWith(anonymous: anonymous);

  /// Checks the parts of the form that aren't text fields. Returns false
  /// (and shows the error) when no category is picked.
  bool validateSelections() {
    if (state.category != null) return true;
    state = state.copyWith(showCategoryError: true);
    return false;
  }

  /// Saves the report. Returns its id, or null if it failed (the error is
  /// in [NewReportState.submission]).
  Future<String?> submit({
    required String title,
    required String description,
    required String location,
  }) async {
    final category = state.category;
    final reporter = ref.read(sessionProvider).profile;
    if (category == null || reporter == null) return null;
    if (state.submission.isLoading) return null;

    state = state.copyWith(submission: const AsyncLoading());
    final result = await AsyncValue.guard(
      () => ref
          .read(reportRepositoryProvider)
          .createReport(
            reporter: reporter,
            photos: state.photos,
            draft: ReportDraft(
              title: title,
              description: description,
              category: category,
              location: location,
              urgency: state.urgency,
              anonymous: state.anonymous,
            ),
          ),
    );
    if (!ref.mounted) return result.value;
    state = state.copyWith(submission: result);
    return result.value;
  }
}

final newReportControllerProvider =
    NotifierProvider.autoDispose<NewReportController, NewReportState>(
      NewReportController.new,
    );
