# Repository Guidelines

## Project Structure & Module Organization
- `lib/` holds Dart source; `lib/main.dart` is the entry point. Core app layers live in `lib/core`, `lib/domain`, and `lib/presentation`.
- `test/` contains unit and widget tests mirroring `lib/` (example: `test/core/services/storage/..._test.dart`).
- `assets/` stores static resources like `assets/icon.png`, declared in `pubspec.yaml`.
- `linux/`, `macos/`, `windows/` are platform host folders; touch only for platform-specific work.
- `build/` is generated output and should not be edited.

## Build, Test, and Development Commands
- `flutter pub get` installs dependencies.
- `flutter run` launches the app locally (desktop target depends on your Flutter setup).
- `flutter test` runs the full test suite under `test/`.
- `flutter analyze` runs static analysis using `analysis_options.yaml`.
- `dart format lib test` formats Dart files with standard conventions.

## Coding Style & Naming Conventions
- Follow Flutter/Dart style and `flutter_lints` rules in `analysis_options.yaml`.
- Use 2-space indentation (enforced by the Dart formatter).
- File names use `lower_snake_case.dart`; classes and enums use `UpperCamelCase`.
- Prefer small, composable widgets and keep UI concerns in `lib/presentation`.

## Testing Guidelines
- Use `flutter_test` for unit and widget tests.
- Name files with the `*_test.dart` suffix and mirror the `lib/` structure.
- Add tests when modifying storage services, DI setup, or theme behavior.

## Commit & Pull Request Guidelines
- Commit messages follow conventional-style prefixes seen in history: `feat:`, `fix:`, `chore:`, `refactor:` with short summaries.
- PRs should include: purpose, linked issue (if applicable), test command(s) run, and screenshots for visual/UI changes.
