import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/theme/app_theme.dart';
import 'package:individual_formative/core/storage/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads the bundled Plus Jakarta Sans so screenshots and text measurements
/// match the app (tests otherwise fall back to a placeholder font).
Future<void> loadAppFonts() async {
  final loader = FontLoader('PlusJakartaSans');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'));
  }
  await loader.load();
}

extension PumpApp on WidgetTester {
  /// Pumps [child] inside the app theme and a [ProviderScope].
  Future<void> pumpApp(
    Widget child, {
    ThemeMode themeMode = ThemeMode.dark,
    List overrides = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...overrides,
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: Scaffold(body: child),
        ),
      ),
    );
  }
}
