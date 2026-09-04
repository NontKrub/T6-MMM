import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { AppleDeletionError } from "../_shared/apple_account_deletion.ts";
import {
  type DeleteAccountDependencies,
  handleDeleteAccount,
} from "./index.ts";
import type { SupabaseClient } from "../_shared/supabase.ts";

const clientId = "com.mixmatchmood.mmm";

Deno.test("malformed deletion requests return a stable client error", async () => {
  const fixture = makeFixture();

  const response = await handleDeleteAccount(
    deleteRequest({ apple_authorization_code: 42 }),
    fixture.dependencies,
  );

  assertEquals(response.status, 400);
  assertEquals(await response.json(), {
    error: "The account deletion request is invalid.",
    code: "apple_identity_invalid",
  });
  assertEquals(fixture.state.markerWrites, 0);
  assertEquals(fixture.state.storageRemoveCalls, 0);
  assertEquals(fixture.state.authDeleteCalls, 0);
});

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
  assertEquals(fixture.state.markerWrites, 2);
  assertEquals(fixture.state.storageRemoveCalls, 1);
  assertEquals(fixture.state.authDeleteCalls, 1);
  assertEquals(fixture.state.appleRevokedAt != null, true);
  assertEquals(fixture.state.appleRefreshToken, null);
});

Deno.test(
  "a marker write failure recovers from the stored Apple refresh token",
  async () => {
    const fixture = makeFixture({ failRevocationMarkerWrites: 1 });

    const firstResponse = await handleDeleteAccount(
      deleteRequest({ apple_authorization_code: "code", apple_nonce: "nonce" }),
      fixture.dependencies,
    );

    assertEquals(firstResponse.status, 500);
    assertEquals(fixture.state.revokeCalls, 1);
    assertEquals(fixture.state.storedRevocationCalls, 0);
    assertEquals(fixture.state.appleRefreshToken, "refresh-token");
    assertEquals(fixture.state.storageRemoveCalls, 0);
    assertEquals(fixture.state.authDeleteCalls, 0);

    const retryResponse = await handleDeleteAccount(
      deleteRequest({}),
      fixture.dependencies,
    );

    assertEquals(retryResponse.status, 200);
    assertEquals(fixture.state.revokeCalls, 1);
    assertEquals(fixture.state.storedRevocationCalls, 1);
    assertEquals(fixture.state.markerWrites, 3);
    assertEquals(fixture.state.appleRefreshToken, null);
    assertEquals(fixture.state.storageRemoveCalls, 1);
    assertEquals(fixture.state.authDeleteCalls, 1);
  },
);

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

Deno.test(
  "expired Apple refresh-token recovery state is purged before retry",
  async () => {
    const fixture = makeFixture({
      appleRefreshToken: "expired-token",
      appleRefreshTokenExpiresAt: "2020-01-01T00:00:00.000Z",
    });

    const response = await handleDeleteAccount(
      deleteRequest({}),
      fixture.dependencies,
    );

    assertEquals(response.status, 400);
    assertEquals(await response.json(), {
      error: "Fresh Sign in with Apple authorization is required.",
      code: "apple_reauthentication_required",
    });
    assertEquals(fixture.state.expiredRefreshTokenClearCalls, 1);
    assertEquals(fixture.state.appleRefreshToken, null);
    assertEquals(fixture.state.revokeCalls, 0);
    assertEquals(fixture.state.storedRevocationCalls, 0);
    assertEquals(fixture.state.storageRemoveCalls, 0);
    assertEquals(fixture.state.authDeleteCalls, 0);
  },
);

Deno.test("storage failure preserves the marker and retry skips revocation", async () => {
  const fixture = makeFixture({ storageShouldFail: true });

  const firstResponse = await handleDeleteAccount(
    deleteRequest({ apple_authorization_code: "code", apple_nonce: "nonce" }),
    fixture.dependencies,
  );

  assertEquals(firstResponse.status, 500);
  assertEquals(fixture.state.revokeCalls, 1);
  assertEquals(fixture.state.markerWrites, 2);
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
  assertEquals(fixture.state.markerWrites, 2);
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
  appleRefreshToken: string | null;
  authDeleteCalls: number;
  authDeleteShouldFail: boolean;
  appleRefreshTokenExpiresAt: string | null;
  expiredRefreshTokenClearCalls: number;
  failRevocationMarkerWrites: number;
  markerWrites: number;
  revokeCalls: number;
  revocationError: AppleDeletionError | null;
  storedRevocationCalls: number;
  storageRemoveCalls: number;
  storageShouldFail: boolean;
};

function makeFixture(overrides: Partial<FixtureState> = {}): {
  dependencies: Partial<DeleteAccountDependencies>;
  state: FixtureState;
} {
  const state: FixtureState = {
    appleRevokedAt: null,
    appleRefreshToken: null,
    authDeleteCalls: 0,
    authDeleteShouldFail: false,
    appleRefreshTokenExpiresAt: null,
    expiredRefreshTokenClearCalls: 0,
    failRevocationMarkerWrites: 0,
    markerWrites: 0,
    revokeCalls: 0,
    revocationError: null,
    storedRevocationCalls: 0,
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
                    ? state.appleRefreshToken == null ? null : {
                      apple_revoked_at: null,
                      apple_refresh_token: state.appleRefreshToken,
                      apple_refresh_token_expires_at:
                        state.appleRefreshTokenExpiresAt ?? new Date(
                          Date.now() + 60_000,
                        ).toISOString(),
                    }
                    : {
                      apple_revoked_at: state.appleRevokedAt,
                      apple_refresh_token: state.appleRefreshToken,
                      apple_refresh_token_expires_at:
                        state.appleRefreshTokenExpiresAt ?? new Date(
                          Date.now() + 60_000,
                        ).toISOString(),
                    },
                  error: null,
                }),
              };
            },
          };
        },
        upsert: async (row: Record<string, unknown>) => {
          state.markerWrites++;
          if (
            "apple_revoked_at" in row &&
            state.failRevocationMarkerWrites > 0
          ) {
            state.failRevocationMarkerWrites--;
            return { error: new Error("marker write failed") };
          }
          if ("apple_revoked_at" in row) {
            state.appleRevokedAt = row.apple_revoked_at as string | null;
            if (row.apple_refresh_token === null) {
              state.appleRefreshToken = null;
            }
          }
          if (typeof row.apple_refresh_token === "string") {
            state.appleRefreshToken = row.apple_refresh_token;
          }
          return { error: null };
        },
        update(row: Record<string, unknown>) {
          return {
            eq: async () => {
              state.expiredRefreshTokenClearCalls++;
              if (row.apple_refresh_token === null) {
                state.appleRefreshToken = null;
                state.appleRefreshTokenExpiresAt = null;
              }
              return { error: null };
            },
          };
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
      revokeAppleAuthorization: async (_params, options) => {
        state.revokeCalls++;
        if (state.revocationError) throw state.revocationError;
        await options?.beforeRevoke?.("refresh-token");
      },
      revokeAppleRefreshToken: async () => {
        state.storedRevocationCalls++;
      },
    },
  };
}

function deleteRequest(body: unknown): Request {
  return new Request("https://example.test/delete-account", {
    method: "POST",
    headers: {
      Authorization: "Bearer test-session",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
}
