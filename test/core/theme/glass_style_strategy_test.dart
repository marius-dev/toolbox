import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/theme/glass_style_strategy.dart';

void main() {
  group('GlassStyleStrategy', () {
    group('ClearGlassStrategy', () {
      const strategy = ClearGlassStrategy();

      test('has correct storage key', () {
        expect(strategy.storageKey, equals('clear'));
      });

      test('has correct display name', () {
        expect(strategy.displayName, equals('Clear'));
      });

      test('has correct blur sigma', () {
        expect(strategy.blurSigma, equals(16.0));
      });

      test('returns correct surface opacity for dark theme', () {
        expect(strategy.surfaceOpacity(true), equals(0.08));
      });

      test('returns correct surface opacity for light theme', () {
        expect(strategy.surfaceOpacity(false), equals(0.24));
      });

      test('returns zero accent opacity (no tint)', () {
        expect(strategy.accentOpacity(true), equals(0.0));
        expect(strategy.accentOpacity(false), equals(0.0));
      });

      test('returns correct border opacity for dark theme', () {
        expect(strategy.borderOpacity(true), equals(0.12));
      });

      test('returns correct border opacity for light theme', () {
        expect(strategy.borderOpacity(false), equals(0.04));
      });

      test('returns correct background gradient opacities for dark theme', () {
        final opacities = strategy.backgroundGradientOpacities(true);
        expect(opacities, hasLength(3));
        expect(opacities[0], equals(0.32)); // start
        expect(opacities[1], equals(0.3)); // middle
        expect(opacities[2], equals(0.42)); // end
      });

      test('returns correct background gradient opacities for light theme', () {
        final opacities = strategy.backgroundGradientOpacities(false);
        expect(opacities, hasLength(3));
        expect(opacities[0], equals(0.55)); // start
        expect(opacities[1], equals(0.5)); // middle
        expect(opacities[2], equals(0.38)); // end
      });

      test('returns zero background accent opacity (no accent overlay)', () {
        expect(strategy.backgroundAccentOpacity(true), equals(0.0));
        expect(strategy.backgroundAccentOpacity(false), equals(0.0));
      });

      test('returns correct glow opacity', () {
        expect(strategy.glowOpacity(), equals(0.25));
      });

      test('returns correct shadow config for dark theme', () {
        final config = strategy.shadowConfig(true);
        expect(config.opacity, equals(0.25));
        expect(config.blurRadius, equals(18.0));
        expect(config.offsetY, equals(10.0));
      });

      test('returns correct shadow config for light theme', () {
        final config = strategy.shadowConfig(false);
        expect(config.opacity, equals(0.08));
        expect(config.blurRadius, equals(18.0));
        expect(config.offsetY, equals(10.0));
      });
    });

    group('TintedGlassStrategy', () {
      const strategy = TintedGlassStrategy();

      test('has correct storage key', () {
        expect(strategy.storageKey, equals('tinted'));
      });

      test('has correct display name', () {
        expect(strategy.displayName, equals('Tinted'));
      });

      test('has correct blur sigma', () {
        expect(strategy.blurSigma, equals(24.0));
      });

      test('returns correct surface opacity for dark theme', () {
        expect(strategy.surfaceOpacity(true), equals(0.12));
      });

      test('returns correct surface opacity for light theme', () {
        expect(strategy.surfaceOpacity(false), equals(0.32));
      });

      test('returns correct accent opacity for dark theme', () {
        expect(strategy.accentOpacity(true), equals(0.2));
      });

      test('returns correct accent opacity for light theme', () {
        expect(strategy.accentOpacity(false), equals(0.15));
      });

      test('returns correct border opacity for dark theme', () {
        expect(strategy.borderOpacity(true), equals(0.2));
      });

      test('returns correct border opacity for light theme', () {
        expect(strategy.borderOpacity(false), equals(0.08));
      });

      test('returns correct background gradient opacities for dark theme', () {
        final opacities = strategy.backgroundGradientOpacities(true);
        expect(opacities, hasLength(3));
        expect(opacities[0], equals(0.45)); // start
        expect(opacities[1], equals(0.38)); // middle
        expect(opacities[2], equals(0.6)); // end
      });

      test('returns correct background gradient opacities for light theme', () {
        final opacities = strategy.backgroundGradientOpacities(false);
        expect(opacities, hasLength(3));
        expect(opacities[0], equals(0.82)); // start
        expect(opacities[1], equals(0.8)); // middle
        expect(opacities[2], equals(0.65)); // end
      });

      test('returns correct background accent opacity for dark theme', () {
        expect(strategy.backgroundAccentOpacity(true), equals(0.18));
      });

      test('returns correct background accent opacity for light theme', () {
        expect(strategy.backgroundAccentOpacity(false), equals(0.08));
      });

      test('returns correct glow opacity', () {
        expect(strategy.glowOpacity(), equals(0.6));
      });

      test('returns correct shadow config for dark theme', () {
        final config = strategy.shadowConfig(true);
        expect(config.opacity, equals(0.55));
        expect(config.blurRadius, equals(30.0));
        expect(config.offsetY, equals(16.0));
      });

      test('returns correct shadow config for light theme', () {
        final config = strategy.shadowConfig(false);
        expect(config.opacity, equals(0.18));
        expect(config.blurRadius, equals(30.0));
        expect(config.offsetY, equals(16.0));
      });
    });

    group('Strategy Differences', () {
      const clear = ClearGlassStrategy();
      const tinted = TintedGlassStrategy();

      test('tinted has higher blur than clear', () {
        expect(tinted.blurSigma, greaterThan(clear.blurSigma));
      });

      test('tinted has higher surface opacity than clear', () {
        expect(
          tinted.surfaceOpacity(true),
          greaterThan(clear.surfaceOpacity(true)),
        );
        expect(
          tinted.surfaceOpacity(false),
          greaterThan(clear.surfaceOpacity(false)),
        );
      });

      test('only tinted has accent tinting', () {
        expect(clear.accentOpacity(true), equals(0.0));
        expect(clear.accentOpacity(false), equals(0.0));
        expect(tinted.accentOpacity(true), greaterThan(0.0));
        expect(tinted.accentOpacity(false), greaterThan(0.0));
      });

      test('tinted has stronger glow', () {
        expect(tinted.glowOpacity(), greaterThan(clear.glowOpacity()));
      });

      test('tinted has stronger shadows', () {
        final clearShadow = clear.shadowConfig(true);
        final tintedShadow = tinted.shadowConfig(true);
        expect(tintedShadow.opacity, greaterThan(clearShadow.opacity));
        expect(tintedShadow.blurRadius, greaterThan(clearShadow.blurRadius));
      });
    });
  });
}
