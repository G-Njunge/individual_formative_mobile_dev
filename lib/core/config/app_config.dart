/// App-wide constants that are not part of the visual design.
class AppConfig {
  AppConfig._();

  /// Working name of the product. Change it here to rename the app everywhere.
  static const appName = 'Ripoti';

  /// Students must sign up with one of these email domains.
  static const studentEmailDomains = ['alustudent.com'];

  /// Staff must sign up with one of these email domains.
  static const staffEmailDomains = ['alueducation.com'];

  static const maxPhotos = 3;
  static const maxDescriptionLength = 300;
  static const minPasswordLength = 8;

  /// Photos are stored in Firestore (no Storage on the free plan), so they are
  /// compressed hard before upload to keep every document well under 1 MiB.
  static const photoMaxWidth = 1024.0;
  static const photoQuality = 60;
  static const photoMaxBytes = 700 * 1024;
}
