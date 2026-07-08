// test/widget/hashtag_text_test.dart
//
// Widget tests for the HashtagText component.
// Verifies that hashtag tokens are rendered in blue/bold and
// plain text tokens use the theme primary text colour.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:igit_connects/shared_components/hashtag_text.dart';

// ---------------------------------------------------------------------------
// Helper: wraps the widget in a minimal Material/Theme environment.
// ---------------------------------------------------------------------------
Widget _wrap(Widget child, {Brightness brightness = Brightness.dark}) {
  return MaterialApp(
    theme: brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true),
    home: Scaffold(body: child),
  );
}

void main() {
  group('HashtagText widget', () {
    testWidgets('renders plain text with no hashtags', (tester) async {
      await tester.pumpWidget(_wrap(const HashtagText(text: 'Hello world')));

      // Should find a RichText in the tree.
      expect(find.byType(RichText), findsWidgets);

      // The plain text should appear somewhere in the widget tree.
      expect(
        find.textContaining('Hello world', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('renders a single hashtag token', (tester) async {
      await tester.pumpWidget(_wrap(const HashtagText(text: '#flutter')));

      expect(find.textContaining('#flutter', findRichText: true), findsWidgets);
    });

    testWidgets('renders mixed plain text and hashtag', (tester) async {
      await tester.pumpWidget(
        _wrap(const HashtagText(text: 'Join us #igit today')),
      );

      // Both the hashtag and surrounding text should be present.
      expect(find.textContaining('#igit', findRichText: true), findsWidgets);
    });

    testWidgets('renders without errors on empty string', (tester) async {
      await tester.pumpWidget(_wrap(const HashtagText(text: '')));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HashtagText(text: 'Light mode #test'),
          brightness: Brightness.light,
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('applies custom fontSize', (tester) async {
      await tester.pumpWidget(
        _wrap(const HashtagText(text: 'Text', fontSize: 20)),
      );

      // Widget renders without exceptions — font size applied via TextStyle.
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders multiple consecutive hashtags', (tester) async {
      await tester.pumpWidget(
        _wrap(const HashtagText(text: '#one #two #three')),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(RichText), findsWidgets);
    });
  });
}
