import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  AppleDeletionError,
  type AppleJwkSet,
  revokeVerifiedAppleAuthorizationCode,
  verifyAppleIdentityToken,
} from "./apple_account_deletion.ts";

const encoder = new TextEncoder();
const clientId = "com.mixmatchmood.mmm";
const expectedSubject = "apple-subject-a";
const now = 1_700_000_000;

Deno.test("Apple identity tokens use the Apple-shaped RSA JWK flow", async () => {
  const { privateKey, jwks } = await rsaFixture();
  const rawNonce = "test-raw-nonce";
  const token = await signedToken(privateKey, {
    sub: expectedSubject,
    aud: clientId,
    iss: "https://appleid.apple.com",
    exp: now + 300,
    nonce: await nonceHash(rawNonce),
  });

  const claims = await verifyAppleIdentityToken(token, rawNonce, {
    clientId,
    expectedSubject,
    now,
    jwks,
  });
  assertEquals(claims.sub, expectedSubject);

  for (
    const [name, changes] of Object.entries({
      subject: { sub: "apple-subject-b" },
      audience: { aud: "another-client" },
      issuer: { iss: "https://example.invalid" },
      expiry: { exp: now - 1 },
      nonce: { nonce: await nonceHash("another-nonce") },
    })
  ) {
    await expectInvalid(
      signedToken(privateKey, {
        sub: expectedSubject,
        aud: clientId,
        iss: "https://appleid.apple.com",
        exp: now + 300,
        nonce: await nonceHash(rawNonce),
        ...changes,
      }),
      rawNonce,
      { clientId, expectedSubject, now, jwks },
      name,
    );
  }
});

Deno.test("Apple identity verification rejects unsafe JWT shapes", async () => {
  const { privateKey, jwks } = await rsaFixture();
  const rawNonce = "test-raw-nonce";
  const claims = {
    sub: expectedSubject,
    aud: clientId,
    iss: "https://appleid.apple.com",
    exp: now + 300,
    nonce: await nonceHash(rawNonce),
  };

  await expectInvalid(
    signedToken(privateKey, claims, { alg: "ES256" }),
    rawNonce,
    { clientId, expectedSubject, now, jwks },
    "unsupported algorithm",
  );
  await expectInvalid(
    signedToken(privateKey, claims, { kid: "unknown-key" }),
    rawNonce,
    { clientId, expectedSubject, now, jwks },
    "unknown key id",
  );
  await expectInvalid(
    signedToken(privateKey, claims),
    rawNonce,
    {
      clientId,
      expectedSubject,
      now,
      jwks: { keys: [{ ...jwks.keys[0], kty: "EC" }] },
    },
    "wrong key type",
  );

  const [header, payload, signature] = (await signedToken(privateKey, claims))
    .split(".");
  const tampered = `${header}.${payload}.${signature[0] === "A" ? "B" : "A"}${
    signature.slice(1)
  }`;
  await expectInvalid(
    tampered,
    rawNonce,
    { clientId, expectedSubject, now, jwks },
    "invalid signature",
  );
  await expectInvalid(
    "not-a-jwt",
    rawNonce,
    { clientId, expectedSubject, now, jwks },
    "malformed JWT",
  );
});

Deno.test("authorization-code exchange verifies and revokes its returned identity", async () => {
  const { privateKey, jwks } = await rsaFixture();
  const rawNonce = "exchange-raw-nonce";
  const idToken = await signedToken(privateKey, {
    sub: expectedSubject,
    aud: clientId,
    iss: "https://appleid.apple.com",
    exp: now + 300,
    nonce: await nonceHash(rawNonce),
  });
  let tokenCalls = 0;
  let revokeCalls = 0;
  let revokedToken = "";

  const claims = await revokeVerifiedAppleAuthorizationCode(
    {
      authorizationCode: "authorization-code-a",
      rawNonce,
      clientId,
      expectedSubject,
    },
    {
      clientSecret: "test-client-secret",
      jwks,
      now,
      fetchToken: async (url, init) => {
        tokenCalls++;
        assertEquals(url, "https://appleid.apple.com/auth/token");
        assertEquals(init?.method, "POST");
        const body = new URLSearchParams(init?.body as string);
        assertEquals(body.get("code"), "authorization-code-a");
        return jsonResponse({
          refresh_token: "refresh-token-a",
          id_token: idToken,
        });
      },
      fetchRevoke: async (url, init) => {
        revokeCalls++;
        assertEquals(url, "https://appleid.apple.com/auth/revoke");
        const body = new URLSearchParams(init?.body as string);
        revokedToken = body.get("token") ?? "";
        return new Response(null, { status: 200 });
      },
    },
  );

  assertEquals(claims.sub, expectedSubject);
  assertEquals(tokenCalls, 1);
  assertEquals(revokeCalls, 1);
  assertEquals(revokedToken, "refresh-token-a");
});

Deno.test("a code for Apple B cannot revoke an account linked to Apple A", async () => {
  const { privateKey, jwks } = await rsaFixture();
  const rawNonce = "mixed-identity-nonce";
  const tokenForB = await signedToken(privateKey, {
    sub: "apple-subject-b",
    aud: clientId,
    iss: "https://appleid.apple.com",
    exp: now + 300,
    nonce: await nonceHash(rawNonce),
  });
  let revokeCalls = 0;

  const error = await assertRejects(
    () =>
      revokeVerifiedAppleAuthorizationCode(
        {
          authorizationCode: "authorization-code-b",
          rawNonce,
          clientId,
          expectedSubject,
        },
        {
          clientSecret: "test-client-secret",
          jwks,
          now,
          fetchToken: async () =>
            jsonResponse({
              refresh_token: "refresh-token-b",
              id_token: tokenForB,
            }),
          fetchRevoke: async () => {
            revokeCalls++;
            return new Response(null, { status: 200 });
          },
        },
      ),
    AppleDeletionError,
  );
  assertEquals((error as AppleDeletionError).code, "apple_identity_invalid");
  assertEquals(revokeCalls, 0);
});

Deno.test("Apple exchange fails closed for incomplete or failed responses", async () => {
  const cases: Array<{
    name: string;
    tokenResponse: Response;
    expectedCode: string;
    revoke?: boolean;
  }> = [
    {
      name: "token endpoint client error",
      tokenResponse: new Response(null, { status: 400 }),
      expectedCode: "apple_identity_invalid",
    },
    {
      name: "token endpoint server error",
      tokenResponse: new Response(null, { status: 503 }),
      expectedCode: "apple_revocation_failed",
    },
    {
      name: "missing refresh token",
      tokenResponse: jsonResponse({ id_token: "token" }),
      expectedCode: "apple_identity_invalid",
    },
    {
      name: "missing identity token",
      tokenResponse: jsonResponse({ refresh_token: "refresh" }),
      expectedCode: "apple_identity_invalid",
    },
    {
      name: "null token response",
      tokenResponse: jsonResponse(null),
      expectedCode: "apple_identity_invalid",
    },
  ];

  for (const testCase of cases) {
    let revokeCalls = 0;
    const error = await assertRejects(
      () =>
        revokeVerifiedAppleAuthorizationCode(
          {
            authorizationCode: "code",
            rawNonce: "nonce",
            clientId,
            expectedSubject,
          },
          {
            clientSecret: "test-client-secret",
            fetchToken: async () => testCase.tokenResponse,
            fetchRevoke: async () => {
              revokeCalls++;
              return new Response(null, { status: 200 });
            },
          },
        ),
      AppleDeletionError,
    );
    assertEquals(
      (error as AppleDeletionError).code,
      testCase.expectedCode,
      testCase.name,
    );
    assertEquals(revokeCalls, 0, testCase.name);
  }
});

Deno.test("Apple revocation failure prevents successful completion", async () => {
  const { privateKey, jwks } = await rsaFixture();
  const rawNonce = "revoke-failure-nonce";
  const idToken = await signedToken(privateKey, {
    sub: expectedSubject,
    aud: clientId,
    iss: "https://appleid.apple.com",
    exp: now + 300,
    nonce: await nonceHash(rawNonce),
  });

  const error = await assertRejects(
    () =>
      revokeVerifiedAppleAuthorizationCode(
        { authorizationCode: "code", rawNonce, clientId, expectedSubject },
        {
          clientSecret: "test-client-secret",
          jwks,
          now,
          fetchToken: async () =>
            jsonResponse({ refresh_token: "refresh", id_token: idToken }),
          fetchRevoke: async () => new Response(null, { status: 500 }),
        },
      ),
    AppleDeletionError,
  );
  assertEquals((error as AppleDeletionError).code, "apple_revocation_failed");
});

async function rsaFixture(): Promise<{
  privateKey: CryptoKey;
  jwks: AppleJwkSet;
}> {
  const keyPair = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  ) as CryptoKeyPair;
  const publicJwk = await crypto.subtle.exportKey("jwk", keyPair.publicKey);
  return {
    privateKey: keyPair.privateKey,
    jwks: {
      keys: [{ ...publicJwk, kid: "test-key", alg: "RS256", use: "sig" }],
    },
  };
}

async function expectInvalid(
  tokenPromise: string | Promise<string>,
  rawNonce: string,
  options: {
    clientId: string;
    expectedSubject: string;
    now: number;
    jwks: AppleJwkSet;
  },
  name: string,
): Promise<void> {
  const error = await assertRejects(
    async () => verifyAppleIdentityToken(await tokenPromise, rawNonce, options),
    AppleDeletionError,
  );
  assertEquals(
    (error as AppleDeletionError).code,
    "apple_identity_invalid",
    name,
  );
}

async function signedToken(
  privateKey: CryptoKey,
  claims: Record<string, unknown>,
  headerChanges: Record<string, unknown> = {},
): Promise<string> {
  const header = encode({
    alg: "RS256",
    kid: "test-key",
    typ: "JWT",
    ...headerChanges,
  });
  const payload = encode(claims);
  const input = `${header}.${payload}`;
  const signature = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    privateKey,
    encoder.encode(input),
  );
  return `${input}.${base64Url(new Uint8Array(signature))}`;
}

async function nonceHash(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(value));
  return Array.from(
    new Uint8Array(digest),
    (byte) => byte.toString(16).padStart(2, "0"),
  ).join("");
}

function jsonResponse(body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

function encode(value: unknown): string {
  return base64Url(encoder.encode(JSON.stringify(value)));
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}
