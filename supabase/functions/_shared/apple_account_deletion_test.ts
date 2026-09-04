import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { verifyAppleIdentityToken } from "./apple_account_deletion.ts";

const encoder = new TextEncoder();

Deno.test("Apple deletion credentials require a valid signed identity token", async () => {
  const keyPair = await crypto.subtle.generateKey(
    { name: "ECDSA", namedCurve: "P-256" },
    true,
    ["sign", "verify"],
  );
  const publicJwk = await crypto.subtle.exportKey("jwk", keyPair.publicKey);
  const jwks = {
    keys: [{ ...publicJwk, kid: "test-key", alg: "ES256", use: "sig" }],
  };
  const rawNonce = "test-raw-nonce";
  const token = await signedToken(keyPair.privateKey, {
    sub: "apple-subject",
    aud: "com.mixmatchmood.mmm",
    iss: "https://appleid.apple.com",
    exp: Math.floor(Date.now() / 1000) + 300,
    nonce: await nonceHash(rawNonce),
  });

  await verifyAppleIdentityToken(token, rawNonce, {
    clientId: "com.mixmatchmood.mmm",
    subject: "apple-subject",
    jwks,
  });

  for (const [name, changes] of Object.entries({
    subject: { sub: "another-subject" },
    audience: { aud: "another-client" },
    issuer: { iss: "https://example.invalid" },
    expiry: { exp: Math.floor(Date.now() / 1000) - 1 },
    nonce: { nonce: await nonceHash("another-nonce") },
  })) {
    const invalid = await signedToken(keyPair.privateKey, {
      sub: "apple-subject",
      aud: "com.mixmatchmood.mmm",
      iss: "https://appleid.apple.com",
      exp: Math.floor(Date.now() / 1000) + 300,
      nonce: await nonceHash(rawNonce),
      ...changes,
    });
    await assertRejects(
      () => verifyAppleIdentityToken(invalid, rawNonce, {
        clientId: "com.mixmatchmood.mmm",
        subject: "apple-subject",
        jwks,
      }),
      Error,
      undefined,
      `${name} token was accepted`,
    );
  }

  const [header, payload, signature] = token.split(".");
  const tampered = `${header}.${payload}.${signature[0] === "A" ? "B" : "A"}${signature.slice(1)}`;
  await assertRejects(
    () => verifyAppleIdentityToken(tampered, rawNonce, {
      clientId: "com.mixmatchmood.mmm",
      subject: "apple-subject",
      jwks,
    }),
    Error,
    undefined,
    "invalid signature was accepted",
  );

  assertEquals(true, true);
});

async function signedToken(
  privateKey: CryptoKey,
  claims: Record<string, unknown>,
): Promise<string> {
  const header = encode({ alg: "ES256", kid: "test-key", typ: "JWT" });
  const payload = encode(claims);
  const input = `${header}.${payload}`;
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    privateKey,
    encoder.encode(input),
  );
  return `${input}.${base64Url(new Uint8Array(signature))}`;
}

async function nonceHash(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(value));
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
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
