const appleTokenEndpoint = "https://appleid.apple.com/auth/token";
const appleRevokeEndpoint = "https://appleid.apple.com/auth/revoke";

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
    throw new Error(`Apple authorization exchange failed (${tokenResponse.status}).`);
  }
  const tokenPayload = await tokenResponse.json() as {
    refresh_token?: unknown;
  };
  if (typeof tokenPayload.refresh_token !== "string" ||
      !tokenPayload.refresh_token) {
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
    throw new Error(`Apple token revocation failed (${revokeResponse.status}).`);
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
