import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export type SupabaseClient = ReturnType<typeof createClient>;

export function userClient(req: Request): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const authorization = req.headers.get("Authorization");

  if (!url || !anonKey) {
    throw new Error("Supabase environment variables are not configured.");
  }
  if (!authorization) {
    throw new Error("Missing Authorization header.");
  }

  return createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
}

export function serviceClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!url || !serviceRoleKey) {
    throw new Error("Supabase service environment variables are not configured.");
  }

  return createClient(url, serviceRoleKey);
}

export async function requireUser(req: Request): Promise<{
  supabase: SupabaseClient;
  userId: string;
}> {
  const supabase = userClient(req);
  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) {
    throw new Error("Invalid or expired session.");
  }
  return { supabase, userId: data.user.id };
}
