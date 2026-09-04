const appleTokenEndpoint = "https://appleid.apple.com/auth/token";
const appleRevokeEndpoint = "https://appleid.apple.com/auth/revoke";
const appleJwksEndpoint = "https://appleid.apple.com/auth/keys";

export type AppleJwkSet = {
  keys: AppleJsonWebKey[];
};

type AppleJsonWebKey = JsonWebKey & {
  kid?: string;
  alg?: string;
  use?: string;
};

export type AppleIdentityTokenClaims = {
  iss: string;
  aud: string | string[];
  exp: number;
  nonce: string;
  sub: string;
};

export async function verifyAppleIdentityToken(
  identityToken: string,
  rawNonce: string,
  options: {
    clientId: string;
    subject: string;
    now?: number;
    jwks?: AppleJwkSet;
    fetchJwks?: () => Promise<AppleJwkSet>;
  },
): Promise<AppleIdentityTokenClaims> {
  if (!identityToken || !rawNonce) {
    throw new Error("A fresh Apple identity token and nonce are required.");
  }
  const parts = identityToken.split(".");
  if (parts.length !== 3) throw new Error("The Apple identity token is invalid.");

  const header = decodeJson(parts[0]);
  const claims = decodeJson(parts[1]) as Partial<AppleIdentityTokenClaims>;
  if (header.alg !== "ES256" || typeof header.kid !== "string") {
    throw new Error("The Apple identity token uses an unsupported key.");
  }
  if (
    typeof claims.iss !== "string" ||
    (typeof claims.aud !== "string" && !Array.isArray(claims.aud)) ||
    typeof claims.exp !== "number" ||
    typeof claims.nonce !== "string" ||
    typeof claims.sub !== "string"
  ) {
    throw new Error("The Apple identity token is missing required claims.");
  }
  if (claims.iss !== "https://appleid.apple.com") {
    throw new Error("The Apple identity token issuer is invalid.");
  }
  const audiences = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
  if (!audiences.includes(options.clientId)) {
    throw new Error("The Apple identity token audience is invalid.");
  }
  const now = options.now ?? Math.floor(Date.now() / 1000);
  if (claims.exp <= now) throw new Error("The Apple identity token has expired.");
  if (claims.sub !== options.subject) {
    throw new Error("The Apple identity does not match the signed-in account.");
  }
  if (claims.nonce !== await nonceHash(rawNonce)) {
    throw new Error("The Apple identity token nonce is invalid.");
  }

  const jwks = options.jwks ?? await (options.fetchJwks ?? fetchAppleJwks)();
  const jwk = jwks.keys.find((key) => key.kid === header.kid);
  if (!jwk) throw new Error("The Apple signing key is unavailable.");
  const key = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["verify"],
  );
  const valid = await crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    base64UrlBytes(parts[2]) as BufferSource,
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
  );
  if (!valid) throw new Error("The Apple identity token signature is invalid.");
  return claims as AppleIdentityTokenClaims;
}

async function fetchAppleJwks(): Promise<AppleJwkSet> {
  const response = await fetch(appleJwksEndpoint);
  if (!response.ok) {
    throw new Error(`Apple signing keys could not be loaded (${response.status}).`);
  }
  const payload = await response.json() as { keys?: unknown };
  if (!Array.isArray(payload.keys)) throw new Error("Apple signing keys are invalid.");
  return { keys: payload.keys as AppleJsonWebKey[] };
}

function decodeJson(value: string): Record<string, unknown> {
  try {
    return JSON.parse(new TextDecoder().decode(base64UrlBytes(value)));
  } catch (_) {
    throw new Error("The Apple identity token is invalid.");
  }
}

async function nonceHash(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
}

export async function revokeAppleAuthorizationCode(
  authorizationCode: string,
): Promise<void> {
  const teamId = required("APPLE_TEAM_ID");
  const keyId = required("APPLE_KEY_ID");
  const clientId = required("APPLE_CLIENT_ID");
  const privateKey = required("APPLE_PRIVATE_KEY");
  const clientSecret = await createClientSecret({
    teamId,
    keyId,
    clientId,
    privateKey,
  });

  const tokenResponse = await fetch(appleTokenEndpoint, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      code: authorizationCode,
      grant_type: "authorization_code",
    }),
  });
  if (!tokenResponse.ok) {
    throw new Error(
      `Apple authorization exchange failed (${tokenResponse.status}).`,
    );
  }
  const tokenPayload = await tokenResponse.json() as {
    refresh_token?: unknown;
  };
  if (
    typeof tokenPayload.refresh_token !== "string" ||
    !tokenPayload.refresh_token
  ) {
    throw new Error("Apple did not return a refresh token for revocation.");
  }

  const revokeResponse = await fetch(appleRevokeEndpoint, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      token: tokenPayload.refresh_token,
      token_type_hint: "refresh_token",
    }),
  });
  if (!revokeResponse.ok) {
    throw new Error(
      `Apple token revocation failed (${revokeResponse.status}).`,
    );
  }
}

async function createClientSecret(params: {
  teamId: string;
  keyId: string;
  clientId: string;
  privateKey: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = encodeJson({ alg: "ES256", kid: params.keyId, typ: "JWT" });
  const payload = encodeJson({
    iss: params.teamId,
    iat: now,
    exp: now + 300,
    aud: "https://appleid.apple.com",
    sub: params.clientId,
  });
  const signingInput = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemBytes(params.privateKey) as BufferSource,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64Url(new Uint8Array(signature))}`;
}

function required(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`${name} is not configured.`);
  return value;
}

function encodeJson(value: unknown): string {
  return base64Url(new TextEncoder().encode(JSON.stringify(value)));
}

function pemBytes(value: string): Uint8Array {
  const base64 = value
    .replace(/\\n/g, "\n")
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const decoded = atob(base64);
  return Uint8Array.from(decoded, (character) => character.charCodeAt(0));
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function base64UrlBytes(value: string): Uint8Array {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized + "=".repeat((4 - normalized.length % 4) % 4);
  const decoded = atob(padded);
  return Uint8Array.from(decoded, (character) => character.charCodeAt(0));
}
