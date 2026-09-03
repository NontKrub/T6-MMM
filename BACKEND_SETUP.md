# Mix Match Mood Backend Setup

## Required Services

- Supabase project with Google and Apple OAuth providers enabled.
- Supabase Storage bucket/migrations from `supabase/migrations`.
- Supabase Edge Functions from `supabase/functions`.
- OpenRouter API key for image analysis, outfit generation, missing pieces, and
  chat.
- Open-Meteo forecast API for weather-aware outfit context.

Facebook OAuth is available only when the Flutter runtime flag enables it and
the Supabase/Meta provider configuration is complete.

## Flutter Runtime Config

Copy the example runtime file and fill in public project configuration:

```sh
cp config/runtime.example.json config/runtime.local.json
flutter run --dart-define-from-file=config/runtime.local.json
```

If `SUPABASE_URL` or `SUPABASE_PUBLISHABLE_KEY` is missing, OAuth sign-in is
shown as unavailable. Continue as guest still creates a local-only account for
profile and wardrobe data; AI/backend features remain locked until Supabase is
configured and the user signs in.

The publishable key is intended for code shipped to mobile clients. It is not a
privileged secret: database grants and RLS enforce access. The Supabase Edge
Function runtime may still expose its managed `SUPABASE_ANON_KEY` to the
user-scoped client and uses `SUPABASE_SERVICE_ROLE_KEY` only for explicitly
privileged server operations. Never place either server value in Flutter code.

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

## Sign in with Apple

The iOS app uses native Sign in with Apple and sends Apple's ID token plus a
nonce to Supabase. Register the bundle ID `com.mixmatchmood.mmm` as an Apple
App ID with the Sign in with Apple capability, add that bundle ID under the
Supabase Apple provider, and refresh the provisioning profile after enabling
the capability. The repository contains the Runner entitlement; Apple
Developer and Supabase provider configuration are still required for a real
login.

Account deletion for Apple users requires these Edge Function secrets so the
short-lived authorization code can be exchanged and revoked server-side:

```sh
supabase secrets set APPLE_TEAM_ID=YOUR_APPLE_TEAM_ID
supabase secrets set APPLE_KEY_ID=YOUR_APPLE_KEY_ID
supabase secrets set APPLE_CLIENT_ID=com.mixmatchmood.mmm
supabase secrets set APPLE_PRIVATE_KEY="$(cat AuthKey_YOUR_KEY_ID.p8)"
```

Do not put the private key or any of these server secrets in Flutter config.

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

## Facebook OAuth

Configure Facebook in Supabase and Meta before setting `ENABLE_FACEBOOK_AUTH`
to `true` in the runtime file. Leave it `false` until the provider has been
verified; the app then hides the Facebook button.

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
supabase functions deploy delete-account
```

## Local security checks

With Docker running, exercise the database policies and the Storage API:

```sh
supabase start
supabase test db
scripts/test_supabase_storage_security.sh
```

The Storage script signs short-lived test JWTs with the local Supabase JWT
secret only. Do not point it at a hosted project.

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
- `delete-account`: authenticates from the caller JWT, removes wardrobe
  Storage objects, revokes Apple authorization when required, and deletes the
  Auth user so database rows cascade.
