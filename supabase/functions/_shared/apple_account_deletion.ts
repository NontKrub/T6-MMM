const appleTokenEndpoint = "https://appleid.apple.com/auth/token";
const appleRevokeEndpoint = "https://appleid.apple.com/auth/revoke";
const appleJwksEndpoint = "https://appleid.apple.com/auth/keys";

export type AppleJwkSet = {
  keys: AppleJsonWebKey[];
};

export type AppleJsonWebKey = JsonWebKey & {
  kid?: string;
  alg?: string;
  use?: string;
  kty?: string;
  n?: string;
  e?: string;
};

export type AppleIdentityTokenClaims = {
  iss: string;
  aud: string | string[];
  exp: number;
  nonce: string;
  sub: string;
};

export type AppleDeletionErrorCode =
  | "apple_reauthentication_required"
  | "apple_identity_invalid"
  | "apple_revocation_failed"
  | "account_deletion_failed";

export class AppleDeletionError extends Error {
  constructor(
    public readonly code: AppleDeletionErrorCode,
    public readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = "AppleDeletionError";
  }
}

type AppleFetch = (
  input: string,
  init?: RequestInit,
) => Promise<Response>;

type AppleVerificationOptions = {
  clientId: string;
  expectedSubject: string;
  now?: number;
  jwks?: AppleJwkSet;
  fetchJwks?: () => Promise<AppleJwkSet>;
};

export type RevokeVerifiedAppleAuthorizationCodeParams = {
  authorizationCode: string;
  rawNonce: string;
  clientId: string;
  expectedSubject: string;
};

type AppleExchangeOptions = {
  clientSecret?: string;
  jwks?: AppleJwkSet;
  fetchJwks?: () => Promise<AppleJwkSet>;
  fetchToken?: AppleFetch;
  fetchRevoke?: AppleFetch;
  now?: number;
};

export async function verifyAppleIdentityToken(
  identityToken: string,
  rawNonce: string,
  options: AppleVerificationOptions,
): Promise<AppleIdentityTokenClaims> {
  if (!identityToken || !rawNonce) {
    throw invalidAppleCredential(
      "A fresh Apple identity token and nonce are required.",
    );
  }

  const parts = identityToken.split(".");
  if (parts.length !== 3 || parts.some((part) => part.length === 0)) {
    throw invalidAppleCredential("The Apple identity token is invalid.");
  }

  let header: Record<string, unknown>;
  let claims: Partial<AppleIdentityTokenClaims>;
  let signature: Uint8Array;
  try {
    header = decodeJson(parts[0]);
    claims = decodeJson(parts[1]) as Partial<AppleIdentityTokenClaims>;
    signature = base64UrlBytes(parts[2]);
  } catch (_) {
    throw invalidAppleCredential("The Apple identity token is invalid.");
  }

  if (
    header.alg !== "RS256" || typeof header.kid !== "string" || !header.kid
  ) {
    throw invalidAppleCredential(
      "The Apple identity token uses an unsupported key.",
    );
  }

  const jwks = options.jwks ?? await loadAppleJwks(options.fetchJwks);
  const jwk = jwks.keys.find((key) => key.kid === header.kid);
  if (!jwk || !isSupportedAppleJwk(jwk)) {
    throw invalidAppleCredential("The Apple signing key is unavailable.");
  }

  let key: CryptoKey;
  try {
    key = await crypto.subtle.importKey(
      "jwk",
      jwk,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["verify"],
    );
  } catch (_) {
    throw invalidAppleCredential("The Apple signing key is invalid.");
  }

  let valid = false;
  try {
    valid = await crypto.subtle.verify(
      { name: "RSASSA-PKCS1-v1_5" },
      key,
      signature as BufferSource,
      new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
    );
  } catch (_) {
    throw invalidAppleCredential(
      "The Apple identity token signature is invalid.",
    );
  }
  if (!valid) {
    throw invalidAppleCredential(
      "The Apple identity token signature is invalid.",
    );
  }

  if (
    typeof claims.iss !== "string" ||
    (typeof claims.aud !== "string" && !Array.isArray(claims.aud)) ||
    typeof claims.exp !== "number" || !Number.isFinite(claims.exp) ||
    typeof claims.nonce !== "string" ||
    typeof claims.sub !== "string"
  ) {
    throw invalidAppleCredential(
      "The Apple identity token is missing required claims.",
    );
  }
  if (claims.iss !== "https://appleid.apple.com") {
    throw invalidAppleCredential("The Apple identity token issuer is invalid.");
  }
  const audiences = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
  if (!audiences.includes(options.clientId)) {
    throw invalidAppleCredential(
      "The Apple identity token audience is invalid.",
    );
  }
  const now = options.now ?? Math.floor(Date.now() / 1000);
  if (claims.exp <= now) {
    throw invalidAppleCredential("The Apple identity token has expired.");
  }
  if (claims.sub !== options.expectedSubject) {
    throw invalidAppleCredential(
      "The Apple identity does not match the signed-in account.",
    );
  }
  if (claims.nonce !== await nonceHash(rawNonce)) {
    throw invalidAppleCredential("The Apple identity token nonce is invalid.");
  }

  return claims as AppleIdentityTokenClaims;
}

export async function revokeVerifiedAppleAuthorizationCode(
  params: RevokeVerifiedAppleAuthorizationCodeParams,
  options: AppleExchangeOptions = {},
): Promise<AppleIdentityTokenClaims> {
  if (!params.authorizationCode.trim() || !params.rawNonce.trim()) {
    throw new AppleDeletionError(
      "apple_reauthentication_required",
      400,
      "Fresh Sign in with Apple authorization is required.",
    );
  }

  let clientSecret: string;
  try {
    clientSecret = options.clientSecret ?? await createConfiguredClientSecret();
  } catch (_) {
    throw new AppleDeletionError(
      "account_deletion_failed",
      500,
      "Apple account deletion is not configured safely.",
    );
  }

  const fetchToken = options.fetchToken ?? (fetch as AppleFetch);
  let tokenResponse: Response;
  try {
    tokenResponse = await fetchToken(appleTokenEndpoint, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: params.clientId,
        client_secret: clientSecret,
        code: params.authorizationCode,
        grant_type: "authorization_code",
      }),
    });
  } catch (_) {
    throw new AppleDeletionError(
      "apple_revocation_failed",
      502,
      "Apple authorization could not be verified.",
    );
  }
  if (!tokenResponse.ok) {
    throw new AppleDeletionError(
      tokenResponse.status >= 500
        ? "apple_revocation_failed"
        : "apple_identity_invalid",
      tokenResponse.status >= 500 ? 502 : 401,
      tokenResponse.status >= 500
        ? "Apple authorization could not be verified."
        : "The Apple authorization is invalid.",
    );
  }

  let tokenPayload: {
    refresh_token?: unknown;
    id_token?: unknown;
  };
  try {
    tokenPayload = await tokenResponse.json() as typeof tokenPayload;
  } catch (_) {
    throw invalidAppleCredential(
      "Apple returned an invalid authorization response.",
    );
  }
  if (
    typeof tokenPayload.refresh_token !== "string" ||
    !tokenPayload.refresh_token ||
    typeof tokenPayload.id_token !== "string" ||
    !tokenPayload.id_token
  ) {
    throw invalidAppleCredential(
      "Apple did not return the credentials required for revocation.",
    );
  }

  const claims = await verifyAppleIdentityToken(
    tokenPayload.id_token,
    params.rawNonce,
    {
      clientId: params.clientId,
      expectedSubject: params.expectedSubject,
      jwks: options.jwks,
      fetchJwks: options.fetchJwks,
      now: options.now,
    },
  );

  let revokeResponse: Response;
  try {
    const fetchRevoke = options.fetchRevoke ?? (fetch as AppleFetch);
    revokeResponse = await fetchRevoke(appleRevokeEndpoint, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: params.clientId,
        client_secret: clientSecret,
        token: tokenPayload.refresh_token,
        token_type_hint: "refresh_token",
      }),
    });
  } catch (_) {
    throw new AppleDeletionError(
      "apple_revocation_failed",
      502,
      "Apple authorization could not be revoked.",
    );
  }
  if (!revokeResponse.ok) {
    throw new AppleDeletionError(
      "apple_revocation_failed",
      revokeResponse.status >= 500 ? 502 : 500,
      "Apple authorization could not be revoked.",
    );
  }
  return claims;
}

async function loadAppleJwks(
  injected?: () => Promise<AppleJwkSet>,
): Promise<AppleJwkSet> {
  try {
    if (injected) return await injected();
    const response = await fetch(appleJwksEndpoint);
    if (!response.ok) {
      throw new Error("Apple signing keys could not be loaded.");
    }
    const payload = await response.json() as { keys?: unknown };
    if (!Array.isArray(payload.keys)) {
      throw new Error("Apple signing keys are invalid.");
    }
    return { keys: payload.keys as AppleJsonWebKey[] };
  } catch (_) {
    throw new AppleDeletionError(
      "apple_identity_invalid",
      502,
      "Apple signing keys could not be loaded.",
    );
  }
}

function isSupportedAppleJwk(jwk: AppleJsonWebKey): boolean {
  return jwk.kty === "RSA" && jwk.alg === "RS256" &&
    (!jwk.use || jwk.use === "sig") &&
    typeof jwk.n === "string" && jwk.n.length > 0 &&
    typeof jwk.e === "string" && jwk.e.length > 0;
}

function invalidAppleCredential(message: string): AppleDeletionError {
  return new AppleDeletionError("apple_identity_invalid", 401, message);
}

async function nonceHash(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(
    new Uint8Array(digest),
    (byte) => byte.toString(16).padStart(2, "0"),
  ).join("");
}

async function createConfiguredClientSecret(): Promise<string> {
  const teamId = required("APPLE_TEAM_ID");
  const keyId = required("APPLE_KEY_ID");
  const clientId = required("APPLE_CLIENT_ID");
  const privateKey = required("APPLE_PRIVATE_KEY");
  return createClientSecret({ teamId, keyId, clientId, privateKey });
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

function decodeJson(value: string): Record<string, unknown> {
  const parsed = JSON.parse(new TextDecoder().decode(base64UrlBytes(value)));
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("The Apple identity token is invalid.");
  }
  return parsed as Record<string, unknown>;
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
