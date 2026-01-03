# Repository Guidelines

## Project Structure & Module Organization
- `lib/` houses the Dart app. `lib/main.dart` boots the Flutter host, while shared logic lives under `lib/core`, `lib/domain`, and `lib/presentation` for UI widgets and screens.
- `assets/` contains bundled imagery and icons referenced by `pubspec.yaml`; keep edits in sync with asset declarations.
- Platform folders (`linux/`, `macos/`, `windows/`) hold host-specific code tuned for desktop builds; do not touch them unless a change is explicitly desktop-related.
- `test/` mirrors the `lib/` tree, including helpers such as `test/test_helpers/path_provider_stub.dart` for dependency stubbing; follow the same module layout when adding new tests.
- Avoid editing `build/`; it houses generated outputs from Flutter tooling.

## Build, Test, and Development Commands
- `flutter pub get` resolves dependencies declared in `pubspec.yaml` and must be rerun after dependency edits.
- `flutter run` (optionally with `-d macos`/`-d windows`/`-d linux`) launches the desktop build for manual validation.
- `flutter test` executes the unit and widget suite under `test/`, covering UI and business logic.
- `flutter analyze` enforces lint rules from `analysis_options.yaml` before commits.
- `dart format lib test` keeps formatting consistent with Dart defaults.

## Coding Style & Naming Conventions
- Follow Dart and Flutter idioms (`flutter_lints`), leveraging 2-space indentation and minimizing long widget methods.
- Files use `lower_snake_case.dart`; classes and enums use `UpperCamelCase` (e.g., `LauncherHeader`), and constants stay `lowerCamelCase` or `kPascalCase` for static consts.
- Prefer descriptive widget names, break large build methods into private helpers, and keep styling logic within `lib/presentation`.

## Testing Guidelines
- Widget and unit tests rely on `flutter_test`; name files with the `_test.dart` suffix and target the same feature directories as the code under test.
- Leverage `test/test_helpers/path_provider_stub.dart` when storage or platform channels are involved, and mock DI providers from `lib/core/di` when instantiating services.
- Run targeted suites (`flutter test test/presentation/...`) for fast verification before pushing commits.

## Commit & Pull Request Guidelines
- Commit messages follow conventional prefixes (`feat:`, `fix:`, `chore:`, `refactor:`) with a short summary (e.g., `fix: close hover menus on exit`).
- PRs should describe the change, link related issues, summarize test commands executed, and include screenshots for UI updates.
