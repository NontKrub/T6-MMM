import {
  batches,
  parseDeleteAccountRequest,
} from "../_shared/account_deletion.ts";
import {
  AppleDeletionError,
  revokeVerifiedAppleAuthorizationCode,
} from "../_shared/apple_account_deletion.ts";
import { handleOptions, jsonResponse, readJson } from "../_shared/http.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";

const bucket = "wardrobe-images";

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") {
    return jsonResponse({ error: "Only POST is supported." }, 405);
  }

  try {
    const { userId } = await requireUser(req);
    const request = parseDeleteAccountRequest(await readJson<unknown>(req));
    const admin = serviceClient();
    const { data, error: userError } = await admin.auth.admin.getUserById(
      userId,
    );
    if (userError && !/not found|does not exist/i.test(userError.message)) {
      throw userError;
    }

    const { data: attempt, error: attemptError } = await admin
      .from("account_deletion_attempts")
      .select("apple_revoked_at")
      .eq("user_id", userId)
      .maybeSingle();
    if (attemptError) throw attemptError;

    if (!data.user) {
      await removeUserStorage(admin, userId);
      return jsonResponse({ deleted: true });
    }

    const appleIdentity = (data.user.identities ?? []).find((identity) =>
      identity.provider === "apple"
    );
    const hasAppleIdentity = appleIdentity != null;

    if (hasAppleIdentity && !attempt?.apple_revoked_at) {
      if (
        !request.appleAuthorizationCode ||
        !request.appleNonce
      ) {
        return jsonResponse({
          error: "Fresh Sign in with Apple authorization is required.",
          code: "apple_reauthentication_required",
        }, 400);
      }
      const providerId = (appleIdentity as unknown as {
        provider_id?: unknown;
      })?.provider_id;
      const clientId = Deno.env.get("APPLE_CLIENT_ID")?.trim();
      if (typeof providerId !== "string" || !providerId || !clientId) {
        throw new Error("Apple account deletion is not configured safely.");
      }
      await revokeVerifiedAppleAuthorizationCode({
        authorizationCode: request.appleAuthorizationCode,
        rawNonce: request.appleNonce,
        clientId,
        expectedSubject: providerId,
      });
      const { error } = await admin.from("account_deletion_attempts").upsert({
        user_id: userId,
        apple_revoked_at: new Date().toISOString(),
      }, { onConflict: "user_id" });
      if (error) throw error;
    }

    await removeUserStorage(admin, userId);

    const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
    if (deleteError && !/not found|user not found/i.test(deleteError.message)) {
      throw deleteError;
    }
    return jsonResponse({ deleted: true });
  } catch (error) {
    const appleError = error instanceof AppleDeletionError ? error : null;
    const code = appleError?.code ?? "account_deletion_failed";
    const status = appleError?.status ?? 500;
    const message = appleError?.message ?? "Account deletion failed.";
    console.error(error instanceof Error ? error.message : message);
    return jsonResponse({
      error: message,
      code,
    }, status);
  }
});

async function removeUserStorage(
  admin: ReturnType<typeof serviceClient>,
  userId: string,
): Promise<void> {
  const storage = admin.storage.from(bucket);
  const paths = await listPaths(storage, userId);
  for (const group of batches(paths, 100)) {
    const { error } = await storage.remove(group);
    if (error) throw error;
  }
}

async function listPaths(
  storage: ReturnType<ReturnType<typeof serviceClient>["storage"]["from"]>,
  prefix: string,
): Promise<string[]> {
  const paths: string[] = [];
  const limit = 1000;
  let offset = 0;
  while (true) {
    const { data, error } = await storage.list(prefix, { limit, offset });
    if (error) throw error;
    const entries = data ?? [];
    for (const entry of entries) {
      const path = `${prefix}/${entry.name}`;
      if (entry.id === null && entry.metadata === null) {
        paths.push(...await listPaths(storage, path));
      } else {
        paths.push(path);
      }
    }
    if (entries.length < limit) break;
    offset += entries.length;
  }
  return paths;
}
