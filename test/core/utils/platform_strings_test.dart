import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/utils/platform_strings.dart';

void main() {
  group('PlatformStrings', () {
    group('File Manager Strings', () {
      test('revealInFileManager returns platform-specific string', () {
        final result = PlatformStrings.revealInFileManager;
        expect(result, isNotEmpty);

        if (Platform.isMacOS) {
          expect(result, equals('Reveal in Finder'));
        } else if (Platform.isWindows) {
          expect(result, equals('Show in Explorer'));
        } else if (Platform.isLinux) {
          expect(result, equals('Show in Files'));
        }
      });

      test('revealProjectInFileManager returns platform-specific string', () {
        final result = PlatformStrings.revealProjectInFileManager();
        expect(result, isNotEmpty);
        expect(result, contains('project'));
      });

      test('revealProjectInFileManager accepts custom item name', () {
        final result = PlatformStrings.revealProjectInFileManager(
          itemName: 'workspace',
        );
        expect(result, contains('workspace'));
        expect(result, isNot(contains('project')));
      });

      test('fileManagerName returns platform-specific name', () {
        final result = PlatformStrings.fileManagerName;
        expect(result, isNotEmpty);

        if (Platform.isMacOS) {
          expect(result, equals('Finder'));
        } else if (Platform.isWindows) {
          expect(result, equals('Explorer'));
        } else if (Platform.isLinux) {
          expect(result, equals('Files'));
        }
      });
    });

    group('Terminal Strings', () {
      test('openInTerminal returns platform-specific string', () {
        final result = PlatformStrings.openInTerminal;
        expect(result, isNotEmpty);

        if (Platform.isWindows) {
          expect(result, equals('Open in Command Prompt'));
        } else {
          expect(result, equals('Open in Terminal'));
        }
      });

      test('openProjectInTerminal returns platform-specific string', () {
        final result = PlatformStrings.openProjectInTerminal();
        expect(result, isNotEmpty);
        expect(result, contains('project'));
      });

      test('openProjectInTerminal accepts custom item name', () {
        final result = PlatformStrings.openProjectInTerminal(
          itemName: 'folder',
        );
        expect(result, contains('folder'));
        expect(result, isNot(contains('project')));
      });

      test('terminalName returns platform-specific name', () {
        final result = PlatformStrings.terminalName;
        expect(result, isNotEmpty);

        if (Platform.isWindows) {
          expect(result, equals('Command Prompt'));
        } else {
          expect(result, equals('Terminal'));
        }
      });
    });

    group('Keyboard Modifier Strings', () {
      test('primaryModifier returns platform-specific modifier', () {
        final result = PlatformStrings.primaryModifier;
        expect(result, isNotEmpty);

        if (Platform.isMacOS) {
          expect(result, equals('⌘'));
        } else {
          expect(result, equals('Ctrl'));
        }
      });

      test('primaryModifierName returns platform-specific name', () {
        final result = PlatformStrings.primaryModifierName;
        expect(result, isNotEmpty);

        if (Platform.isMacOS) {
          expect(result, equals('Command'));
        } else {
          expect(result, equals('Control'));
        }
      });

      test('secondaryModifier returns platform-specific modifier', () {
        final result = PlatformStrings.secondaryModifier;
        expect(result, isNotEmpty);

        if (Platform.isMacOS) {
          expect(result, equals('⌥'));
        } else {
          expect(result, equals('Alt'));
        }
      });

      test('secondaryModifierName returns platform-specific name', () {
        final result = PlatformStrings.secondaryModifierName;
        expect(result, isNotEmpty);

        if (Platform.isMacOS) {
          expect(result, equals('Option'));
        } else {
          expect(result, equals('Alt'));
        }
      });

      test('shiftModifier returns shift symbol', () {
        expect(PlatformStrings.shiftModifier, equals('⇧'));
      });

      test('shiftModifierName returns Shift', () {
        expect(PlatformStrings.shiftModifierName, equals('Shift'));
      });
    });

    group('Application Menu Strings', () {
      test('preferencesLabel returns platform-specific label', () {
        final result = PlatformStrings.preferencesLabel;
        expect(result, isNotEmpty);

        if (Platform.isMacOS) {
          expect(result, equals('Preferences...'));
        } else {
          expect(result, equals('Settings...'));
        }
      });

      test('quitApplication returns platform-specific quit label', () {
        final result = PlatformStrings.quitApplication(appName: 'TestApp');
        expect(result, contains('TestApp'));

        if (Platform.isMacOS) {
          expect(result, equals('Quit TestApp'));
        } else {
          expect(result, equals('Exit TestApp'));
        }
      });
    });

    group('Path Utilities', () {
      test('pathSeparator returns platform separator', () {
        final result = PlatformStrings.pathSeparator;
        expect(result, equals(Platform.pathSeparator));
      });

      test('formatPath converts forward slashes on Windows', () {
        final input = 'path/to/file';
        final result = PlatformStrings.formatPath(input);

        if (Platform.isWindows) {
          expect(result, equals('path\\to\\file'));
        } else {
          expect(result, equals(input));
        }
      });

      test('formatPath preserves path on non-Windows', () {
        if (!Platform.isWindows) {
          const input = 'path/to/file';
          final result = PlatformStrings.formatPath(input);
          expect(result, equals(input));
        }
      });
    });

    group('Utility Methods', () {
      test('isMacOS returns Platform.isMacOS', () {
        expect(PlatformStrings.isMacOS, equals(Platform.isMacOS));
      });

      test('isWindows returns Platform.isWindows', () {
        expect(PlatformStrings.isWindows, equals(Platform.isWindows));
      });

      test('isLinux returns Platform.isLinux', () {
        expect(PlatformStrings.isLinux, equals(Platform.isLinux));
      });

      test('platformName returns current platform name', () {
        final result = PlatformStrings.platformName;
        expect(result, isNotEmpty);

        if (Platform.isMacOS) {
          expect(result, equals('macOS'));
        } else if (Platform.isWindows) {
          expect(result, equals('Windows'));
        } else if (Platform.isLinux) {
          expect(result, equals('Linux'));
        }
      });
    });
  });
}
