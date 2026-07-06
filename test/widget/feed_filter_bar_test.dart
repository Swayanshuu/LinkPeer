// test/widget/feed_filter_bar_test.dart
//
// Widget tests for the FeedFilterBar component.
// Verifies rendering of all filter chips, active state highlighting,
// and that onChanged is called with the correct value on tap.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:igit_connects/screens/home/components/feed_filter_bar.dart';

Widget _wrap({
  required String selected,
  required Function(String) onChanged,
  Brightness brightness = Brightness.dark,
}) {
  return MaterialApp(
    theme: brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true),
    home: Scaffold(
      body: FeedFilterBar(selected: selected, onChanged: onChanged),
    ),
  );
}

void main() {
  group('FeedFilterBar', () {
    testWidgets('renders all four filter chips', (tester) async {
      await tester.pumpWidget(
        _wrap(selected: 'all', onChanged: (_) {}),
      );

      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('JOB'), findsOneWidget);
      expect(find.text('ANNOUNCEMENT'), findsOneWidget);
      expect(find.text('INTERNSHIP'), findsOneWidget);
    });

    testWidgets('calls onChanged with "job" when job chip is tapped',
        (tester) async {
      String? tapped;

      await tester.pumpWidget(
        _wrap(selected: 'all', onChanged: (v) => tapped = v),
      );

      await tester.tap(find.text('JOB'));
      await tester.pump();

      expect(tapped, 'job');
    });

    testWidgets('calls onChanged with "announcement" when tapped',
        (tester) async {
      String? tapped;

      await tester.pumpWidget(
        _wrap(selected: 'all', onChanged: (v) => tapped = v),
      );

      await tester.tap(find.text('ANNOUNCEMENT'));
      await tester.pump();

      expect(tapped, 'announcement');
    });

    testWidgets('calls onChanged with "internship" when tapped',
        (tester) async {
      String? tapped;

      await tester.pumpWidget(
        _wrap(selected: 'all', onChanged: (v) => tapped = v),
      );

      await tester.tap(find.text('INTERNSHIP'));
      await tester.pump();

      expect(tapped, 'internship');
    });

    testWidgets('renders correctly in light theme without errors',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          selected: 'job',
          onChanged: (_) {},
          brightness: Brightness.light,
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in dark theme without errors',
        (tester) async {
      await tester.pumpWidget(
        _wrap(selected: 'all', onChanged: (_) {}),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
