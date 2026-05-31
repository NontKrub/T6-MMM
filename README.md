# Mix Match Mood

Mix Match Mood, or MMM for short, is a Flutter wardrobe assistant that helps you catalog clothing, generate outfits, find missing pieces, and get style guidance based on your closet, mood, and context.

## Features

- Wardrobe catalog with clothing categories, colors, seasons, and usage history.
- Outfit generation for everyday planning and in-a-rush recommendations.
- Fashion chat assistant backed by Supabase Edge Functions.
- Missing-piece suggestions and repetition insights.
- Guest/mock mode when Supabase configuration is not provided.

## Getting Started

Install dependencies:

```sh
flutter pub get
```

Run locally in guest/mock mode:

```sh
flutter run
```

Run against Supabase:

```sh
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=AUTH_REDIRECT_URL=mmm://login-callback
```

## Quality Checks

```sh
flutter analyze
flutter test
dart format lib test
```

## Backend

Supabase migrations live in `supabase/migrations/`, and Edge Functions live in `supabase/functions/`. See `BACKEND_SETUP.md` for required Supabase, OpenAI, and weather configuration.
