import {
  assert,
  assertFalse,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  aiConsentPolicyVersion,
  aiConsentType,
  hasAiConsent,
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

Deno.test("hasAiConsent reads every field required by the validator", async () => {
  const row = currentConsent("user-a");
  const client = {
    from: () => new ConsentQuery(row),
  };

  assert(await hasAiConsent(client, "user-a"));
});

Deno.test("hasAiConsent rejects stale, revoked, foreign, and missing consent", async () => {
  const cases = [
    [currentConsent("user-a"), "user-a", true],
    [
      { ...currentConsent("user-a"), revoked_at: "2026-09-04T00:00:00Z" },
      "user-a",
      false,
    ],
    [{ ...currentConsent("user-a"), policy_version: "old" }, "user-a", false],
    [currentConsent("user-b"), "user-a", false],
    [null, "user-a", false],
  ] as const;

  for (const [row, userId, expected] of cases) {
    const actual = await hasAiConsent(
      { from: () => new ConsentQuery(row) },
      userId,
    );
    assert(actual === expected);
  }
});

Deno.test("hasAiConsent surfaces consent query errors", async () => {
  await assertRejects(
    () =>
      hasAiConsent(
        { from: () => new ConsentQuery(null, new Error("db down")) },
        "user-a",
      ),
    Error,
    "db down",
  );
});

function currentConsent(userId: string) {
  return {
    user_id: userId,
    consent_type: aiConsentType,
    policy_version: aiConsentPolicyVersion,
    revoked_at: null,
  };
}

class ConsentQuery {
  constructor(
    private readonly row: Record<string, unknown> | null,
    private readonly failure: Error | null = null,
  ) {}

  private columns = "";

  select(columns: string) {
    this.columns = columns;
    return this;
  }

  eq() {
    return this;
  }

  is() {
    return this;
  }

  limit() {
    if (this.failure) {
      return Promise.resolve({ data: null, error: this.failure });
    }
    const selected = new Set(
      this.columns.split(",").map((value) => value.trim()),
    );
    const data = this.row === null ? [] : selected.has("consent_type") &&
        selected.has("policy_version") && selected.has("revoked_at")
      ? [this.row]
      : [{ user_id: this.row.user_id }];
    return Promise.resolve({ data, error: null });
  }
}
