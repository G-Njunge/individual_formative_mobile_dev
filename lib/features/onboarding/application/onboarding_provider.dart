import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/shared_preferences_provider.dart';

/// Whether this device has seen the onboarding carousel. Stored on the
/// device (not the account), because onboarding happens before sign-in.
class OnboardingSeen extends Notifier<bool> {
  static const _key = 'onboarding_seen';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

final onboardingSeenProvider = NotifierProvider<OnboardingSeen, bool>(
  OnboardingSeen.new,
);
