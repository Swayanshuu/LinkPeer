// test/unit/theme_provider_test.dart
//
// Unit tests for ThemeNotifier and ThemeProvider.
// Tests cover: loadInitial(), init(), toggle(), setMode(), isDark getter,
// and SharedPreferences persistence behaviour.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igit_connects/core/theme_provider.dart';

void main() {
  // Reset SharedPreferences to a clean state before every test.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeNotifier.loadInitial()', () {
    test('returns ThemeMode.system when no preference is stored', () async {
      final mode = await ThemeNotifier.loadInitial();
      expect(mode, ThemeMode.system);
    });

    test('returns ThemeMode.dark when stored value is "dark"', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final mode = await ThemeNotifier.loadInitial();
      expect(mode, ThemeMode.dark);
    });

    test('returns ThemeMode.light when stored value is "light"', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final mode = await ThemeNotifier.loadInitial();
      expect(mode, ThemeMode.light);
    });

    test('returns ThemeMode.system for an unrecognised stored value', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'invalid'});
      final mode = await ThemeNotifier.loadInitial();
      expect(mode, ThemeMode.system);
    });
  });

  group('ThemeNotifier.init()', () {
    test('seeds provider state without writing to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).init(ThemeMode.dark);
      expect(container.read(themeProvider), ThemeMode.dark);

      // Confirm nothing was written to prefs.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), isNull);
    });
  });

  group('ThemeNotifier.toggle()', () {
    test('toggles from dark to light and persists the result', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).init(ThemeMode.dark);
      await container.read(themeProvider.notifier).toggle();

      expect(container.read(themeProvider), ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('toggles from light to dark and persists the result', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).init(ThemeMode.light);
      await container.read(themeProvider.notifier).toggle();

      expect(container.read(themeProvider), ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test(
      'toggles from system to light (system is treated as non-light)',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Default build() returns ThemeMode.system.
        // toggle() logic: state == ThemeMode.light ? dark : light
        // system != light → resolves to light.
        await container.read(themeProvider.notifier).toggle();

        expect(container.read(themeProvider), ThemeMode.light);
      },
    );
  });

  group('ThemeNotifier.setMode()', () {
    test('sets dark mode and writes "dark" to prefs', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setMode(ThemeMode.dark);
      expect(container.read(themeProvider), ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('sets light mode and writes "light" to prefs', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setMode(ThemeMode.light);
      expect(container.read(themeProvider), ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('sets system mode and removes the prefs key', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setMode(ThemeMode.system);
      expect(container.read(themeProvider), ThemeMode.system);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), isNull);
    });
  });

  group('ThemeNotifier.isDark getter', () {
    test('returns true when state is ThemeMode.dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).init(ThemeMode.dark);
      expect(container.read(themeProvider.notifier).isDark, isTrue);
    });

    test('returns false when state is ThemeMode.light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).init(ThemeMode.light);
      expect(container.read(themeProvider.notifier).isDark, isFalse);
    });

    test('returns false when state is ThemeMode.system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default build() = ThemeMode.system.
      expect(container.read(themeProvider.notifier).isDark, isFalse);
    });
  });

  group('Persistence round-trip', () {
    test('toggle persists correctly and loadInitial reads it back', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).init(ThemeMode.light);
      await container.read(themeProvider.notifier).toggle(); // → dark

      // Simulate a cold restart by calling loadInitial again.
      final restored = await ThemeNotifier.loadInitial();
      expect(restored, ThemeMode.dark);
    });
  });
}
