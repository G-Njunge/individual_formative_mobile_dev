import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/user_facing_exception.dart';

/// Picks one photo from the gallery and returns it compressed, ready to store.
///
/// The free Firebase plan has no Storage, so photos go into Firestore
/// documents (1 MiB limit each). `image_picker` resizes to 1024 px and
/// re-encodes as JPEG at quality 60, which brings a phone photo down to
/// roughly 100 to 250 KB.
class PhotoPicker {
  PhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Returns null if the person cancels.
  Future<Uint8List?> pick() async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: AppConfig.photoMaxWidth,
        maxHeight: AppConfig.photoMaxWidth,
        imageQuality: AppConfig.photoQuality,
        requestFullMetadata: false,
      );
    } catch (_) {
      throw const UserFacingException(
        "We couldn't open your photos. Check that Ripoti may use them in "
        'your phone settings.',
      );
    }
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (!file.mimeType.isImageOrUnknown || bytes.isEmpty) {
      throw const UserFacingException('That file is not a photo.');
    }
    if (bytes.lengthInBytes > AppConfig.photoMaxBytes) {
      throw const UserFacingException(
        'That photo is too large even after shrinking it. Try a different '
        'one.',
      );
    }
    return bytes;
  }
}

extension on String? {
  bool get isImageOrUnknown => this == null || this!.startsWith('image/');
}
