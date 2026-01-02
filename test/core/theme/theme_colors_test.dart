import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/theme/theme_colors.dart';

void main() {
  group('ThemeColors', () {
    testWidgets('surfaceColor returns correct opacity for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.surfaceColor(context, opacity: 0.5);
              expect(color, equals(Colors.white.withOpacity(0.5)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('surfaceColor returns correct opacity for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.surfaceColor(context, opacity: 0.5);
              expect(color, equals(Colors.black.withOpacity(0.5)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('baseSurface returns correct color for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.baseSurface(context);
              expect(color, equals(Colors.white.withOpacity(0.05)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('baseSurface returns correct color for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.baseSurface(context);
              expect(color, equals(Colors.black.withOpacity(0.02)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('borderColor returns correct default color for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.borderColor(context);
              expect(color, equals(Colors.white.withOpacity(0.12)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('borderColor returns correct default color for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.borderColor(context);
              expect(color, equals(Colors.black.withOpacity(0.08)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('borderColor accepts custom opacity',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.borderColor(context, opacity: 0.5);
              expect(color, equals(Colors.white.withOpacity(0.5)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('accentWithOpacity returns correct color for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final accent = Colors.blue;
              final color = ThemeColors.accentWithOpacity(
                context,
                accent,
                darkOpacity: 0.9,
                lightOpacity: 0.7,
              );
              expect(color, equals(accent.withOpacity(0.9)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('accentWithOpacity returns correct color for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final accent = Colors.blue;
              final color = ThemeColors.accentWithOpacity(
                context,
                accent,
                darkOpacity: 0.9,
                lightOpacity: 0.7,
              );
              expect(color, equals(accent.withOpacity(0.7)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('iconColor returns default color for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.iconColor(context);
              expect(color, equals(Colors.white.withOpacity(0.9)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('iconColor returns default color for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.iconColor(context);
              expect(color, equals(Colors.black.withOpacity(0.65)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('textColor returns default color for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.textColor(context);
              expect(color, equals(Colors.white.withOpacity(0.9)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('textColor returns default color for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.textColor(context);
              expect(color, equals(Colors.black.withOpacity(0.85)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('secondaryTextColor returns correct color for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.secondaryTextColor(context);
              expect(color, equals(Colors.white.withOpacity(0.6)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('secondaryTextColor returns correct color for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.secondaryTextColor(context);
              expect(color, equals(Colors.black.withOpacity(0.5)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('dividerColor returns correct color for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.dividerColor(context);
              expect(color, equals(Colors.white.withOpacity(0.08)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('dividerColor returns correct color for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final color = ThemeColors.dividerColor(context);
              expect(color, equals(Colors.black.withOpacity(0.06)));
              return Container();
            },
          ),
        ),
      );
    });

    test('dialogBarrierColor returns consistent color', () {
      final color = ThemeColors.dialogBarrierColor();
      expect(color, equals(Colors.black.withOpacity(0.78)));
    });

    testWidgets('shadowColor returns correct color',
        (WidgetTester tester) async {
      final accent = Colors.blue;
      final color = ThemeColors.shadowColor(accent);
      expect(color, equals(accent.withOpacity(0.2)));
    });

    testWidgets('shadowColor accepts custom opacity',
        (WidgetTester tester) async {
      final accent = Colors.blue;
      final color = ThemeColors.shadowColor(accent, opacity: 0.5);
      expect(color, equals(accent.withOpacity(0.5)));
    });
  });
}
