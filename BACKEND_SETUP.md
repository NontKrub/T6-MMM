# Wardrobly Backend Setup

## Required Services

- Supabase project with Google and Facebook OAuth providers enabled.
- Supabase Storage bucket/migrations from `supabase/migrations`.
- Supabase Edge Functions from `supabase/functions`.
- OpenRouter API key for image analysis, outfit generation, missing pieces, and
  chat.
- Open-Meteo forecast API for weather-aware outfit context.

## Flutter Runtime Config

Run Flutter with compile-time environment values:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=AUTH_REDIRECT_URL=wardrobly://login-callback
```

If `SUPABASE_URL` or `SUPABASE_ANON_KEY` is missing, the app stays in local
mock/guest mode.

## OAuth Redirect Setup

In Supabase Dashboard > Authentication > URL Configuration, add this redirect
URL:

```txt
wardrobly://login-callback
```

In Supabase Dashboard > Authentication > Providers, enable Google and Facebook
and enter each provider's client ID and secret. In the Google and Facebook
developer consoles, set the OAuth callback/redirect URI to:

```txt
https://YOUR_PROJECT.supabase.co/auth/v1/callback
```

## Supabase Secrets

Set Edge Function secrets:

```sh
supabase secrets set OPENROUTER_API_KEY=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
supabase secrets set OPENROUTER_MODEL=openai/gpt-oss-120b:free
supabase secrets set WEATHER_API_URL=https://api.open-meteo.com/v1/forecast
```

`OPENROUTER_MODEL` and `WEATHER_API_URL` are optional defaults. Open-Meteo does
not require a weather API key. `OPENAI_API_KEY` and `OPENAI_MODEL` are still
supported as a fallback if `OPENROUTER_API_KEY` is not set.

## Deploy

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
  AI model, and returns category/color/tag metadata.
- `generate-outfits`: creates ranked outfit rows from wardrobe, profile,
  weather, lucky colors, and wear history.
- `rush-outfit`: returns one practical least-recently-worn outfit.
- `weather-context`: normalizes weather into outfit constraints.
- `daily-lucky-colors`: computes colors from profile birth data and date.
- `repetition-insights`: detects repeated colors/styles from recent wear events.
- `missing-pieces`: generates wardrobe gap recommendations.
- `fashion-chat`: stores user/assistant messages and replies with wardrobe-aware
  fashion advice.
