# Mix Match Mood

Mix Match Mood, or MMM for short, is a Flutter wardrobe assistant that helps you catalog clothing, generate outfits, find missing pieces, and get style guidance based on your closet, mood, and context.

## Features

- Wardrobe catalog with clothing categories, pixel-derived HEX colors, pattern,
  silhouette, seasons, and usage history.
- Outfit generation for everyday planning and in-a-rush recommendations, with
  color-aware scoring and order-independent repeat warnings.
- Fashion chat assistant backed by Supabase Edge Functions.
- Missing-piece suggestions and repetition insights.
- Guest local account for profile and wardrobe when Supabase sign-in is not used.

## Getting Started

Install dependencies:

```sh
flutter pub get
```

Run locally with a guest local account:

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
dart format lib test integration_test
flutter analyze
flutter test
deno test supabase/functions/_shared/domain_test.ts
flutter build ios --simulator
```

## Wardrobe image analysis

Imported images are copied from the picker into application-managed storage
before analysis or save, so guest wardrobe images survive picker-cache cleanup
and app restarts. MMM downsamples and quantizes image pixels on-device to
produce a deterministic dominant palette. HEX values are authoritative for
color matching.

On iOS, Apple Vision's on-device `VNClassifyImageRequest` supplies real model
labels and confidence. MMM conservatively maps supported labels to category
and style suggestions. Category stays unselected below the confidence
threshold and must be confirmed before save. Raw labels are used only for the
current analysis/debugging and are not persisted.

Pattern and silhouette are suggested only when Vision returns explicit,
high-confidence labels such as `striped`, `oversized`, or `wide leg`;
otherwise they remain `unknown` for manual selection. Users can retain up to
three detected HEX colors, remove or add colors, and choose the primary color.
Signed-in wardrobe sync still uploads images to the configured Supabase
wardrobe bucket and removes its local staging copy after successful upload.

On iOS, the deployment target is 15.0. Camera, photo-library, and location
permissions are requested by their related actions. To run a simulator build:

```sh
xcrun simctl list devices available
flutter run -d <simulator-udid>
```

The simulator build was validated on iPhone 17 Pro with iOS 27.0. The iOS
Simulator can exercise photo-library import. Physical camera capture still
requires a real iPhone.

## Backend

Supabase migrations live in `supabase/migrations/`, and Edge Functions live in `supabase/functions/`. See `BACKEND_SETUP.md` for required Supabase, OpenAI, and weather configuration.
