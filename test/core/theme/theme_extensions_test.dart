import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/theme/theme_extensions.dart';

void main() {
  group('ThemeContextExtensions', () {
    testWidgets('isDark returns true for dark theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              expect(context.isDark, isTrue);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('isDark returns false for light theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              expect(context.isDark, isFalse);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('isLight returns true for light theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              expect(context.isLight, isTrue);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('isLight returns false for dark theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              expect(context.isLight, isFalse);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('theme returns ThemeData', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              expect(context.theme, isA<ThemeData>());
              expect(context.theme, equals(Theme.of(context)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('surfaceColor extension works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = context.surfaceColor(opacity: 0.5);
              expect(color, equals(Colors.white.withValues(alpha: 0.5)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('baseSurface extension works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = context.baseSurface;
              expect(color, equals(Colors.white.withValues(alpha: 0.03)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('borderColor extension works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = context.borderColor();
              expect(color, equals(Colors.white.withValues(alpha: 0.08)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('iconColor extension works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = context.iconColor();
              expect(color, equals(Colors.white.withValues(alpha: 0.9)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('textColor extension works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = context.textColor();
              expect(color, equals(Colors.white.withValues(alpha: 0.9)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('secondaryTextColor extension works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = context.secondaryTextColor;
              expect(color, equals(Colors.white.withValues(alpha: 0.6)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('dividerColor extension works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = context.dividerColor;
              expect(color, equals(Colors.white.withValues(alpha: 0.08)));
              return Container();
            },
          ),
        ),
      );
    });
  });

  group('LayoutContextExtensions', () {
    testWidgets('compactScale returns scale factor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final scale = context.compactScale;
              expect(scale, isA<double>());
              expect(scale, greaterThanOrEqualTo(0.72));
              expect(scale, lessThanOrEqualTo(1.0));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('compactValue scales values correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final scale = context.compactScale;
              final value = context.compactValue(100);
              expect(value, equals(100 * scale));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('compactRadius creates BorderRadius correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final radius = context.compactRadius(10);
              expect(radius, isA<BorderRadius>());
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('compactPadding creates EdgeInsets correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = context.compactPadding(
                horizontal: 16,
                vertical: 8,
              );
              expect(padding, isA<EdgeInsets>());
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('compactPaddingOnly creates EdgeInsets correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = context.compactPaddingOnly(
                left: 10,
                top: 20,
                right: 10,
                bottom: 20,
              );
              expect(padding, isA<EdgeInsets>());
              return Container();
            },
          ),
        ),
      );
    });
  });
}
