/// An error whose message is written for the person using the app. Feature
/// code throws it to control the wording shown in error states and forms.
class UserFacingException implements Exception {
  const UserFacingException(this.message);

  final String message;

  @override
  String toString() => message;
}
