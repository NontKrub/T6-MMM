import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { batches, parseDeleteAccountRequest } from "./account_deletion.ts";

Deno.test("delete requests ignore caller-supplied user ids", () => {
  assertEquals(
    parseDeleteAccountRequest({ user_id: "another-user" }),
    {
      appleAuthorizationCode: null,
      appleIdentityToken: null,
      appleNonce: null,
    },
  );
});

Deno.test("delete requests trim and bound Apple authorization codes", () => {
  assertEquals(
    parseDeleteAccountRequest({ apple_authorization_code: "  code  " }),
    {
      appleAuthorizationCode: "code",
      appleIdentityToken: null,
      appleNonce: null,
    },
  );
  assertThrows(() =>
    parseDeleteAccountRequest({ apple_authorization_code: "x".repeat(4097) })
  );
});

Deno.test("delete requests preserve all fresh Apple credentials", () => {
  assertEquals(
    parseDeleteAccountRequest({
      apple_authorization_code: " code ",
      apple_identity_token: " token ",
      apple_nonce: " nonce ",
    }),
    {
      appleAuthorizationCode: "code",
      appleIdentityToken: "token",
      appleNonce: "nonce",
    },
  );
});

Deno.test("storage deletion is batched", () => {
  assertEquals(batches([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
});
