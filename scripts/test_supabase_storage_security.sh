#!/usr/bin/env bash
set -euo pipefail

# Uses the local Supabase JWT secret only to exercise the local Storage API.
# Never run this against a hosted project with production credentials.
supabase status -o json | deno eval '
const status = JSON.parse(await new Response(Deno.stdin.readable).text());
const encoder = new TextEncoder();

function base64Url(value) {
  const bytes = typeof value === "string" ? encoder.encode(value) : value;
  return btoa(String.fromCharCode(...bytes))
    .replaceAll("=", "")
    .replaceAll("+", "-")
    .replaceAll("/", "_");
}

async function token(userId) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const payload = base64Url(JSON.stringify({
    aud: "authenticated",
    role: "authenticated",
    sub: userId,
    iat: now,
    exp: now + 600,
  }));
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(status.JWT_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "HMAC",
      key,
      encoder.encode(`${header}.${payload}`),
    ),
  );
  return `${header}.${payload}.${base64Url(signature)}`;
}

const ownerId = "10000000-0000-4000-8000-000000000001";
const otherId = "20000000-0000-4000-8000-000000000002";
const ownerToken = await token(ownerId);
const otherToken = await token(otherId);
const objectPath = `${ownerId}/storage-security-${crypto.randomUUID()}.png`;
const objectUrl = `${status.API_URL}/storage/v1/object/wardrobe-images/${objectPath}`;
const headers = (jwt) => ({
  apikey: status.ANON_KEY,
  Authorization: `Bearer ${jwt}`,
});
const check = (condition, message) => {
  if (!condition) throw new Error(message);
};

let uploaded = false;
try {
  const ownerUpload = await fetch(objectUrl, {
    method: "POST",
    headers: { ...headers(ownerToken), "Content-Type": "image/png" },
    body: "mmm",
  });
  check(ownerUpload.status === 200, `owner upload returned ${ownerUpload.status}`);
  uploaded = true;

  const ownerRead = await fetch(objectUrl, { headers: headers(ownerToken) });
  check(ownerRead.status === 200, `owner read returned ${ownerRead.status}`);

  const otherRead = await fetch(objectUrl, { headers: headers(otherToken) });
  check(otherRead.status !== 200, "other user read the owner object");

  const otherUpdate = await fetch(objectUrl, {
    method: "POST",
    headers: {
      ...headers(otherToken),
      "Content-Type": "image/png",
      "x-upsert": "true",
    },
    body: "hacked",
  });
  check(otherUpdate.status !== 200, "other user updated the owner object");

  const otherDelete = await fetch(objectUrl, {
    method: "DELETE",
    headers: headers(otherToken),
  });
  check(otherDelete.status !== 200, "other user deleted the owner object");
} finally {
  if (uploaded) {
    const ownerDelete = await fetch(objectUrl, {
      method: "DELETE",
      headers: headers(ownerToken),
    });
    check(ownerDelete.status === 200, `owner cleanup returned ${ownerDelete.status}`);
  }
}

console.log("Supabase Storage ownership checks passed.");
'
