# MMM release checklist

This checklist is the release gate for TestFlight/App Store builds. A local
compile or unit test does not substitute for hosted Supabase, permission,
visual, network, or physical-device evidence.

## Automated gates

- [PASS] `dart format --output=none --set-exit-if-changed lib test integration_test`
- [PASS] `flutter analyze`
- [PASS] `flutter test` (134 tests)
- [PASS] Deno shared-function tests and function type checks locally and in
  GitHub Actions run `33830101737`
- [PASS] `flutter build ios --simulator`
- [PASS] `flutter build apk --debug` with JDK 17
- [PASS] GitHub Actions workflow run `33830101737` (format, analyze,
  Flutter tests, Deno tests/checks, Supabase DB/Storage security, iOS
  simulator compile, and Android debug compile)

## Backend and security

- [NOT RUN] Apply all new migrations to the hosted project.
- [BLOCKED] Run the two-user RLS and Storage isolation tests against the hosted
  project with disposable users.
- [PASS] Verify Edge Function JWT enforcement and that request-body `user_id`
  values are never authoritative.
- [PASS] Verify the atomic outfit RPC test covers no parent row after invalid
  input (local pgTAP execution is blocked by unavailable Docker here).
- [PASS] Configure only server-side secrets for Edge Functions in repository
  configuration.

## Account, privacy, and AI

- [BLOCKED] Configure and test Google and native Sign in with Apple on a physical
  iPhone.
- [PASS] Gate Facebook behind `ENABLE_FACEBOOK_AUTH=true`; otherwise
  keep the button hidden.
- [BLOCKED] Set `PRIVACY_POLICY_URL` to a real public HTTPS policy and verify it from
  Settings and App Store metadata.
- [PASS] Automated migration retry mapping, tombstone, and local-data
  preservation checks; [BLOCKED] hosted/interrupted-upload verification.
- [PASS] Confirm Sign Out preserves pending local data.
- [BLOCKED] Verify Delete Account removes Storage, database/account data, and Apple
  authorization when applicable.
- [PASS] Verify AI consent is explicit, versioned, revocable, and enforced by each
  AI-capable Edge Function.
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

The current local evidence is passing Flutter and Deno checks, iOS simulator
compile, and Android debug compile when run with the installed JDK 17. CI now
pins the Android job to JDK 17. The default machine JDK is 26 and still fails
Android's JDK-image transform, so local Android builds must use JDK 17.
Local pgTAP/Storage execution is **BLOCKED** because Docker is unavailable.
Computer Use is available, but Device Hub/Xcode accessibility attachment timed
out before an interactive pass; GUI acceptance is **BLOCKED** and no visual
interaction is claimed. Physical-device validation, hosted Supabase
isolation, actual notification delivery, OAuth provider configuration, the
privacy URL, and the 40-image recognition set remain release blockers.
