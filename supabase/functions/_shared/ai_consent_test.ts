import {
  assert,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  aiConsentPolicyVersion,
  aiConsentType,
  isActiveAiConsent,
} from "./ai_consent.ts";

Deno.test("only the current unrevoked consent is active", () => {
  const row = {
    user_id: "user-a",
    consent_type: aiConsentType,
    policy_version: aiConsentPolicyVersion,
    revoked_at: null,
  };
  assert(isActiveAiConsent(row, "user-a"));
  assertFalse(
    isActiveAiConsent({ ...row, revoked_at: "2026-09-04T00:00:00Z" }, "user-a"),
  );
  assertFalse(isActiveAiConsent({ ...row, policy_version: "old" }, "user-a"));
  assertFalse(isActiveAiConsent(row, "user-b"));
});
