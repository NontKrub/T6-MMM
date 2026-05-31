# Repository Guidelines

## Project Structure & Module Organization

This is a Flutter app named `Mix Match Mood` (`MMM` for short). The Dart package is `mix_match_mood`. App code lives in `lib/`: `features/` contains screen-level flows, `core/` contains shared services, providers, navigation, config, and theme, and `shared/` contains reusable models, widgets, and mock data. Tests live in `test/`, currently starting with `widget_test.dart`. Static app assets are declared in `pubspec.yaml` under `assets/avatars/`, `assets/images/`, and `assets/images/mock_clothes/`. Native shells are in `android/` and `ios/`. Supabase backend code lives in `supabase/`, with SQL migrations in `supabase/migrations/` and Edge Functions in `supabase/functions/`.

## Build, Test, and Development Commands

- `flutter pub get`: install Dart and Flutter dependencies.
- `flutter run`: run the app locally, using mock/guest mode if backend defines are absent.
- `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=AUTH_REDIRECT_URL=mmm://login-callback`: run against Supabase.
- `flutter analyze`: run static analysis using `analysis_options.yaml`.
- `flutter test`: run the Flutter test suite.
- `dart format lib test`: format Dart source and tests.
- `supabase db push`: apply migrations to a linked Supabase project.
- `supabase functions deploy <function-name>`: deploy one Edge Function, such as `generate-outfits`.

## Coding Style & Naming Conventions

Follow `package:flutter_lints/flutter.yaml`; this repo only overrides `unnecessary_underscores`. Use two-space Dart formatting via `dart format`. Name Dart files with `snake_case.dart`, classes and widgets with `PascalCase`, and providers/services with descriptive suffixes such as `WardrobeProvider` or `AuthService`. Keep feature UI under `lib/features/<feature>/`, cross-feature widgets under `lib/shared/widgets/`, and backend access behind `lib/core/services/`.

## Testing Guidelines

Use `flutter_test` for widget and unit tests. Place tests under `test/` and name files `*_test.dart`. Prefer focused tests around providers, repositories, navigation behavior, and important screens. Run `flutter test` before submitting changes; run `flutter analyze` when touching Dart code.

## Commit & Pull Request Guidelines

This checkout has no Git history available, so no existing commit convention can be inferred. Use concise, imperative commit messages, for example `Add outfit generation loading state`. Pull requests should include a short summary, test results, linked issue or task when available, and screenshots or screen recordings for UI changes.

## Security & Configuration Tips

Do not commit API keys or Supabase secrets. Runtime Flutter config should be passed with `--dart-define`; Edge Function secrets should be set with `supabase secrets set`. See `BACKEND_SETUP.md` for required Supabase, OpenAI, and weather configuration.
