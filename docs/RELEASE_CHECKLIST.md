# MMM release checklist

This checklist is the release gate for TestFlight/App Store builds. A local
compile or unit test does not substitute for hosted Supabase, permission,
visual, network, or physical-device evidence.

## Automated gates

- [ ] `dart format --output=none --set-exit-if-changed lib test integration_test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Deno shared-function tests and function type checks
- [ ] `flutter build ios --simulator`
- [ ] `flutter build apk --debug`
- [ ] GitHub Actions workflow passes and required checks are protected on the
  production branch

## Backend and security

- [ ] Apply all new migrations to the hosted project.
- [ ] Run the two-user RLS and Storage isolation tests against the hosted
  project with disposable users.
- [ ] Verify Edge Function JWT enforcement and that request-body `user_id`
  values are never authoritative.
- [ ] Verify the atomic outfit RPC leaves no parent row after invalid input.
- [ ] Configure only server-side secrets for Edge Functions.

## Account, privacy, and AI

- [ ] Configure and test Google and native Sign in with Apple on a physical
  iPhone.
- [ ] Configure Facebook before setting `ENABLE_FACEBOOK_AUTH=true`; otherwise
  keep the button hidden.
- [ ] Set `PRIVACY_POLICY_URL` to a real public HTTPS policy and verify it from
  Settings and App Store metadata.
- [ ] Verify guest-to-cloud migration after interrupted uploads and confirm
  Sign Out preserves pending local data.
- [ ] Verify Delete Account removes Storage, database/account data, and Apple
  authorization when applicable.
- [ ] Verify AI consent is explicit, versioned, revocable, and enforced by each
  AI-capable Edge Function.
- [ ] Confirm App Store Connect privacy answers match the deployed data flows.

## Notifications and recognition

- [ ] Test notification permission allow/deny on iOS and Android.
- [ ] Test daily reminder delivery, restart recovery, timezone changes, and
  daylight-saving transitions where applicable.
- [ ] Test repetition threshold crossing and one-alert debouncing.
- [ ] Supply the owned/licensed 40-image non-personal evaluation set described
  in `integration_test/fixtures/clothing/evaluation_manifest.example.json`.
- [ ] Record local/server recognition results and review the measured accuracy;
  do not market guest recognition as automatic if the threshold is missed.

## Current local evidence

The current implementation has passing local Flutter/Deno/database checks and
automated five-test iOS 27 Device Hub simulator smoke coverage. Computer Use is
not available in this environment, so GUI acceptance is **NOT EXECUTED**.
The local Android build was attempted but stopped before compilation because
the machine has not accepted the Android NDK `28.2.13676358` license.
Physical-device full-matrix validation, hosted Supabase isolation, actual
notification delivery, OAuth provider configuration, and the 40-image
recognition set remain release blockers until separately evidenced.
