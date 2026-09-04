export type DeleteAccountRequest = {
  appleAuthorizationCode: string | null;
  appleNonce: string | null;
};

export function parseDeleteAccountRequest(
  body: unknown,
): DeleteAccountRequest {
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    throw new Error("Request body must be a JSON object.");
  }
  const bodyRecord = body as Record<string, unknown>;
  const code = boundedString(
    bodyRecord.apple_authorization_code,
    4096,
    "authorization code",
  );
  const nonce = boundedString(bodyRecord.apple_nonce, 256, "nonce");
  return {
    appleAuthorizationCode: code,
    appleNonce: nonce,
  };
}

function boundedString(
  value: unknown,
  maxLength: number,
  label: string,
): string | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== "string" || value.length > maxLength) {
    throw new Error(`The Apple ${label} is invalid.`);
  }
  const trimmed = value.trim();
  return trimmed || null;
}

export function batches<T>(values: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let index = 0; index < values.length; index += size) {
    result.push(values.slice(index, index + size));
  }
  return result;
}
