import { batches, parseDeleteAccountRequest } from "../_shared/account_deletion.ts";
import { revokeAppleAuthorizationCode } from "../_shared/apple_account_deletion.ts";
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
    const { data, error: userError } = await admin.auth.admin.getUserById(userId);
    if (userError || !data.user) {
      return jsonResponse({ deleted: true });
    }

    const hasAppleIdentity = (data.user.identities ?? []).some((identity) =>
      identity.provider === "apple"
    );
    const { data: attempt } = await admin
      .from("account_deletion_attempts")
      .select("apple_revoked_at")
      .eq("user_id", userId)
      .maybeSingle();

    await removeUserStorage(admin, userId);

    if (hasAppleIdentity && !attempt?.apple_revoked_at) {
      if (!request.appleAuthorizationCode) {
        return jsonResponse({
          error: "Fresh Sign in with Apple authorization is required.",
          code: "apple_reauthentication_required",
        }, 400);
      }
      await revokeAppleAuthorizationCode(request.appleAuthorizationCode);
      await admin.from("account_deletion_attempts").upsert({
        user_id: userId,
        apple_revoked_at: new Date().toISOString(),
      }, { onConflict: "user_id" });
    }

    const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
    if (deleteError && !/not found|user not found/i.test(deleteError.message)) {
      throw deleteError;
    }
    return jsonResponse({ deleted: true });
  } catch (error) {
    console.error(
      error instanceof Error ? error.message : "Account deletion failed.",
    );
    return jsonResponse({
      error: error instanceof Error ? error.message : "Account deletion failed.",
    }, 500);
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
  const { data, error } = await storage.list(prefix, { limit: 1000 });
  if (error) throw error;
  const paths: string[] = [];
  for (const entry of data ?? []) {
    const path = `${prefix}/${entry.name}`;
    if (entry.id === null && entry.metadata === null) {
      paths.push(...await listPaths(storage, path));
    } else {
      paths.push(path);
    }
  }
  return paths;
}
