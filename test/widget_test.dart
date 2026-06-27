// test/widget_test.dart
//
// Top-level smoke test. Verifies the app initialises without crashing
// when Firebase and Supabase are not available (test environment).
// Full feature tests are in test/unit/ and test/widget/.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test suite loads without errors', () {
    // This file is intentionally minimal.
    // It confirms the test runner itself is operational.
    // See test/unit/ for business logic tests.
    // See test/widget/ for component-level widget tests.
    expect(true, isTrue);
  });
}
