# MMM release checklist

This checklist is the release gate for TestFlight/App Store builds. A local
compile or unit test does not substitute for hosted Supabase, permission,
visual, network, or physical-device evidence.

## Automated gates

- [PASS] `dart format --output=none --set-exit-if-changed lib test integration_test`
- [PASS] `flutter analyze`
- [PASS] `flutter test` (145 tests)
- [PASS] Deno shared-function, Apple deletion handler, and function type checks
  locally (59 tests) and in GitHub Actions run `33867345439`
- [PASS] `flutter build ios --simulator`
- [PASS] `flutter build ios --release --no-codesign`
- [PASS] `flutter build apk --debug` with CI JDK 17
- [PASS] `flutter build appbundle --release` with an ephemeral CI keystore;
  the generated AAB passed `jarsigner -verify -certs`.
- [PASS] GitHub Actions workflow run `33867345439` at code SHA
  `c452df3cad960379bdf8c0b31d55fbc1ca53b68d` (format, analyze, Flutter
  tests, Deno tests/checks, local Supabase DB/Storage security, iOS simulator
  and device-release compilation, Android debug and release AAB compilation,
  runtime preflight, and tracked-secret guard).

## Backend and security

- [NOT RUN] Apply all new migrations to the hosted project.
- [BLOCKED] Run the two-user RLS and Storage isolation tests against the hosted
  project with disposable users.
- [PASS] Verify Edge Function JWT enforcement and that request-body `user_id`
  values are never authoritative; account deletion remains server-driven and
  Apple deletion recovery tokens are purged request-time and by a minutely
  `pg_cron` job.
- [PASS] Verify the atomic outfit RPC test covers no parent row after invalid
  input in CI; local pgTAP execution is blocked by unavailable Docker here.
- [PASS] Configure only server-side secrets for Edge Functions in repository
  configuration.

## Account, privacy, and AI

- [BLOCKED] Configure and test Google and native Sign in with Apple on a physical
  iPhone.
- [PASS] Gate Facebook behind `ENABLE_FACEBOOK_AUTH=true`; otherwise
  keep the button hidden.
- [BLOCKED] Set `PRIVACY_POLICY_URL` to a real public HTTPS policy and verify it from
  Settings and App Store metadata.
- [PASS] Automated migration retry mapping, tombstone, warning, and local-data
  preservation checks; [BLOCKED] hosted/interrupted-upload verification.
- [PASS] Confirm Sign Out preserves pending local data.
- [BLOCKED] Verify Delete Account removes Storage, database/account data, and Apple
  authorization when applicable.
- [PASS] Verify AI consent is explicit, versioned, revocable, and enforced by each
  AI-capable Edge Function. Fashion Chat transmits only the documented
  `color_season` style field, not a full profile row.
- [BLOCKED] Confirm App Store Connect privacy answers match the deployed data flows.

## Notifications and recognition

- [NOT RUN] Test notification permission allow/deny on iOS and Android.
- [NOT RUN] Test daily reminder delivery, restart recovery, timezone changes, and
  daylight-saving transitions where applicable.
- [PASS] Unit-test repetition threshold crossing and one-alert debouncing;
  [NOT RUN] OS delivery.
- [BLOCKED] Supply the owned/licensed 40-image non-personal evaluation set described
  in `integration_test/fixtures/clothing/evaluation_manifest.example.json`.
- [NOT RUN] Record local/server recognition results and review the measured accuracy;
  do not market guest recognition as automatic if the threshold is missed.

## Current local evidence

The current local evidence is passing 145 Flutter tests, 59 Deno tests, dynamic
type checks for every Edge Function entrypoint, iOS simulator and unsigned
device-release compilation. GitHub Actions run `33867345439` passed all ten
jobs at code SHA `c452df3cad960379bdf8c0b31d55fbc1ca53b68d`, including local
Supabase pgTAP/Storage security and an ephemerally signed Android release AAB.
CI pins Android to JDK 17; the default local JDK is 26, so local Android builds
remain **BLOCKED** by toolchain availability. Local pgTAP/Storage execution is
**BLOCKED** because Docker is unavailable. Computer Use is available, but its
Device Hub attachment timed out before an interactive pass; GUI acceptance is
**BLOCKED** and no visual interaction is claimed. Physical-device validation,
hosted Supabase isolation, actual notification delivery, OAuth provider
configuration, a public privacy URL, the 40-image recognition set, real
distribution signing/TestFlight, independent-review authentication, and
main-branch protection remain release blockers or manual admin actions.
