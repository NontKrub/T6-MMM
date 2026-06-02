# Mix Match Mood Backend Setup

## Required Services

- Supabase project with Google OAuth provider enabled.
- Supabase Storage bucket/migrations from `supabase/migrations`.
- Supabase Edge Functions from `supabase/functions`.
- OpenRouter API key for image analysis, outfit generation, missing pieces, and
  chat.
- Open-Meteo forecast API for weather-aware outfit context.

Facebook OAuth is intentionally out of scope for this build. Do not add a
Facebook provider, login button, redirect setup, or related secrets unless that
scope changes later.

## Flutter Runtime Config

Run Flutter with compile-time environment values:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=AUTH_REDIRECT_URL=mmm://login-callback
```

If `SUPABASE_URL` or `SUPABASE_ANON_KEY` is missing, OAuth sign-in is shown as
unavailable. Continue as guest still creates a local-only account for profile
and wardrobe data; AI/backend features remain locked until Supabase is
configured and the user signs in.

## OAuth Redirect Setup

In Supabase Dashboard > Authentication > URL Configuration, add this redirect
URL:

```txt
mmm://login-callback
```

In Supabase Dashboard > Authentication > Providers, enable Google and enter
the provider client ID and secret. In the Google developer console, set the
OAuth callback/redirect URI to:

```txt
https://YOUR_PROJECT.supabase.co/auth/v1/callback
```

## Supabase Secrets

Set Edge Function secrets:

```sh
supabase secrets set OPENROUTER_API_KEY=YOUR_OPENROUTER_API_KEY
supabase secrets set OPENROUTER_MODEL=openai/gpt-oss-120b:free
supabase secrets set WEATHER_API_URL=https://api.open-meteo.com/v1/forecast
```

`OPENROUTER_MODEL` and `WEATHER_API_URL` are optional defaults. Open-Meteo does
not require a weather API key. `OPENAI_API_KEY` and `OPENAI_MODEL` are still
supported as a fallback if `OPENROUTER_API_KEY` is not set.

## Deploy

This checkout is intended to deploy to the linked Supabase project
`khrurzvtmpwaxclznnhk`. Confirm the link before pushing changes:

```sh
supabase projects list
```

```sh
supabase db push
supabase functions deploy analyze-clothing-image
supabase functions deploy generate-outfits
supabase functions deploy rush-outfit
supabase functions deploy weather-context
supabase functions deploy daily-lucky-colors
supabase functions deploy repetition-insights
supabase functions deploy missing-pieces
supabase functions deploy fashion-chat
```

## Backend Surface

- `analyze-clothing-image`: signs a wardrobe image, sends it to the configured
  AI model, and returns category/color/tag metadata. If the AI request fails,
  it returns conservative metadata marked with `needs-review` instead of
  blocking wardrobe entry creation.
- `generate-outfits`: creates ranked outfit rows from wardrobe, profile,
  weather, lucky colors, and wear history. If AI ranking fails, it falls back
  to deterministic outfit scoring.
- `rush-outfit`: returns one practical least-recently-worn outfit.
- `weather-context`: normalizes weather into outfit constraints.
- `daily-lucky-colors`: computes colors from profile birth data and date.
  `birth_weekday` is derived automatically from `birth_date` by a database
  trigger when the profile is saved.
- `repetition-insights`: detects repeated colors/styles from recent wear events.
- `missing-pieces`: generates wardrobe gap recommendations, replaces previous
  active recommendations to avoid duplicates, and supports dismissing a
  recommendation through the existing `dismissed_at` column.
- `fashion-chat`: stores user/assistant messages and replies with wardrobe-aware
  fashion advice.
