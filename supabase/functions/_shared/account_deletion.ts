export type DeleteAccountRequest = {
  appleAuthorizationCode: string | null;
};

export function parseDeleteAccountRequest(
  body: unknown,
): DeleteAccountRequest {
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    throw new Error("Request body must be a JSON object.");
  }
  const raw = (body as Record<string, unknown>).apple_authorization_code;
  if (raw === undefined || raw === null) {
    return { appleAuthorizationCode: null };
  }
  if (typeof raw !== "string" || raw.length > 4096) {
    throw new Error("The Apple authorization code is invalid.");
  }
  const code = raw.trim();
  return { appleAuthorizationCode: code || null };
}

export function batches<T>(values: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let index = 0; index < values.length; index += size) {
    result.push(values.slice(index, index + size));
  }
  return result;
}
