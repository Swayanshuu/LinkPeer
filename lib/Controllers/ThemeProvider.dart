import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ThemeProvider — persists and provides the current ThemeMode across the app.
//
// Behaviour:
//  • First launch → ThemeMode.system  (follows the device dark/light setting)
//  • After user manually toggles → saves 'dark' or 'light' to SharedPreferences
//  • On every subsequent launch → restores the saved user preference
//
// Usage:
//   // Read current mode
//   final mode = ref.watch(themeProvider);
//
//   // Toggle between dark ↔ light
//   ref.read(themeProvider.notifier).toggle();
//
//   // Initialise before runApp (call from main):
//   final initialMode = await ThemeNotifier.loadInitial();
// ─────────────────────────────────────────────────────────────────────────────

const _prefKey = 'theme_mode'; // 'dark' | 'light'  (absent = follow system)

class ThemeNotifier extends Notifier<ThemeMode> {
  /// Call this in main() BEFORE runApp() to read the stored preference
  /// synchronously so there is no theme flash on startup.
  static Future<ThemeMode> loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored == 'light') return ThemeMode.light;
    if (stored == 'dark') return ThemeMode.dark;
    // No preference saved yet → honour the device system setting
    return ThemeMode.system;
  }

  @override
  ThemeMode build() {
    // The real initial value is injected via ProviderScope overrides in main().
    // This fallback is only reached in tests / unexpected hot-restarts.
    return ThemeMode.system;
  }

  /// Called from main() to seed the pre-loaded preference without persisting again.
  void init(ThemeMode mode) {
    state = mode;
  }

  /// Toggles between dark and light and persists the choice.
  Future<void> toggle() async {
    // If currently following system, resolve the actual brightness first
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, next == ThemeMode.dark ? 'dark' : 'light');
  }

  /// Set a specific mode explicitly and persist it.
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.system) {
      await prefs.remove(_prefKey); // system → no stored preference
    } else {
      await prefs.setString(_prefKey, mode == ThemeMode.dark ? 'dark' : 'light');
    }
  }

  bool get isDark => state == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
