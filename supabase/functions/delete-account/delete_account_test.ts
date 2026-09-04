import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { AppleDeletionError } from "../_shared/apple_account_deletion.ts";
import {
  type DeleteAccountDependencies,
  handleDeleteAccount,
} from "./index.ts";
import type { SupabaseClient } from "../_shared/supabase.ts";

const clientId = "com.mixmatchmood.mmm";

Deno.test("Apple verification failure performs no destructive deletion", async () => {
  const fixture = makeFixture({
    revocationError: new AppleDeletionError(
      "apple_identity_invalid",
      401,
      "The Apple authorization is invalid.",
    ),
  });

  const response = await handleDeleteAccount(
    deleteRequest({ apple_authorization_code: "code", apple_nonce: "nonce" }),
    fixture.dependencies,
  );

  assertEquals(response.status, 401);
  assertEquals(await response.json(), {
    error: "The Apple authorization is invalid.",
    code: "apple_identity_invalid",
  });
  assertEquals(fixture.state.revokeCalls, 1);
  assertEquals(fixture.state.markerWrites, 0);
  assertEquals(fixture.state.storageRemoveCalls, 0);
  assertEquals(fixture.state.authDeleteCalls, 0);
});

Deno.test("successful Apple deletion marks revocation before cleanup", async () => {
  const fixture = makeFixture();

  const response = await handleDeleteAccount(
    deleteRequest({ apple_authorization_code: "code", apple_nonce: "nonce" }),
    fixture.dependencies,
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { deleted: true });
  assertEquals(fixture.state.revokeCalls, 1);
  assertEquals(fixture.state.markerWrites, 1);
  assertEquals(fixture.state.storageRemoveCalls, 1);
  assertEquals(fixture.state.authDeleteCalls, 1);
  assertEquals(fixture.state.appleRevokedAt != null, true);
});

Deno.test("a retry with recorded Apple revocation skips a second revoke", async () => {
  const fixture = makeFixture({ appleRevokedAt: "2026-09-04T00:00:00.000Z" });

  const response = await handleDeleteAccount(
    deleteRequest({}),
    fixture.dependencies,
  );

  assertEquals(response.status, 200);
  assertEquals(fixture.state.revokeCalls, 0);
  assertEquals(fixture.state.markerWrites, 0);
  assertEquals(fixture.state.storageRemoveCalls, 1);
  assertEquals(fixture.state.authDeleteCalls, 1);
});

Deno.test("storage failure preserves the marker and retry skips revocation", async () => {
  const fixture = makeFixture({ storageShouldFail: true });

  const firstResponse = await handleDeleteAccount(
    deleteRequest({ apple_authorization_code: "code", apple_nonce: "nonce" }),
    fixture.dependencies,
  );

  assertEquals(firstResponse.status, 500);
  assertEquals(fixture.state.revokeCalls, 1);
  assertEquals(fixture.state.markerWrites, 1);
  assertEquals(fixture.state.authDeleteCalls, 0);

  fixture.state.storageShouldFail = false;
  const retryResponse = await handleDeleteAccount(
    deleteRequest({}),
    fixture.dependencies,
  );

  assertEquals(retryResponse.status, 200);
  assertEquals(fixture.state.revokeCalls, 1);
  assertEquals(fixture.state.storageRemoveCalls, 2);
  assertEquals(fixture.state.authDeleteCalls, 1);
});

Deno.test("Auth deletion failure can be retried after revocation and storage cleanup", async () => {
  const fixture = makeFixture({ authDeleteShouldFail: true });

  const firstResponse = await handleDeleteAccount(
    deleteRequest({ apple_authorization_code: "code", apple_nonce: "nonce" }),
    fixture.dependencies,
  );

  assertEquals(firstResponse.status, 500);
  assertEquals(fixture.state.revokeCalls, 1);
  assertEquals(fixture.state.markerWrites, 1);
  assertEquals(fixture.state.storageRemoveCalls, 1);

  fixture.state.authDeleteShouldFail = false;
  const retryResponse = await handleDeleteAccount(
    deleteRequest({}),
    fixture.dependencies,
  );

  assertEquals(retryResponse.status, 200);
  assertEquals(fixture.state.revokeCalls, 1);
  assertEquals(fixture.state.storageRemoveCalls, 2);
  assertEquals(fixture.state.authDeleteCalls, 2);
});

type FixtureState = {
  appleRevokedAt: string | null;
  authDeleteCalls: number;
  authDeleteShouldFail: boolean;
  markerWrites: number;
  revokeCalls: number;
  revocationError: AppleDeletionError | null;
  storageRemoveCalls: number;
  storageShouldFail: boolean;
};

function makeFixture(overrides: Partial<FixtureState> = {}): {
  dependencies: Partial<DeleteAccountDependencies>;
  state: FixtureState;
} {
  const state: FixtureState = {
    appleRevokedAt: null,
    authDeleteCalls: 0,
    authDeleteShouldFail: false,
    markerWrites: 0,
    revokeCalls: 0,
    revocationError: null,
    storageRemoveCalls: 0,
    storageShouldFail: false,
    ...overrides,
  };
  const user = {
    id: "user-a",
    identities: [{ provider: "apple", provider_id: "apple-a" }],
  };
  const admin = {
    auth: {
      admin: {
        getUserById: async () => ({ data: { user }, error: null }),
        deleteUser: async () => {
          state.authDeleteCalls++;
          return state.authDeleteShouldFail
            ? { data: null, error: new Error("auth delete failed") }
            : { data: null, error: null };
        },
      },
    },
    from(table: string) {
      if (table !== "account_deletion_attempts") {
        throw new Error(`unexpected table: ${table}`);
      }
      return {
        select() {
          return {
            eq() {
              return {
                maybeSingle: async () => ({
                  data: state.appleRevokedAt == null
                    ? null
                    : { apple_revoked_at: state.appleRevokedAt },
                  error: null,
                }),
              };
            },
          };
        },
        upsert: async (row: { apple_revoked_at: string }) => {
          state.markerWrites++;
          state.appleRevokedAt = row.apple_revoked_at;
          return { error: null };
        },
      };
    },
    storage: {
      from() {
        return {
          list: async () => ({
            data: [{ name: "image.jpg", id: "file-id", metadata: {} }],
            error: null,
          }),
          remove: async (paths: string[]) => {
            state.storageRemoveCalls++;
            return state.storageShouldFail
              ? { data: null, error: new Error("storage remove failed") }
              : { data: paths, error: null };
          },
        };
      },
    },
  } as unknown as ReturnType<DeleteAccountDependencies["serviceClient"]>;

  return {
    state,
    dependencies: {
      requireUser: async () => ({
        userId: "user-a",
        supabase: {} as SupabaseClient,
      }),
      serviceClient: () => admin,
      appleClientId: () => clientId,
      revokeAppleAuthorization: async () => {
        state.revokeCalls++;
        if (state.revocationError) throw state.revocationError;
      },
    },
  };
}

function deleteRequest(body: Record<string, unknown>): Request {
  return new Request("https://example.test/delete-account", {
    method: "POST",
    headers: {
      Authorization: "Bearer test-session",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
}
