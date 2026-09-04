import type { SupabaseClient } from "./supabase.ts";

export async function assertChatThreadOwner(
  supabase: SupabaseClient,
  threadId: string,
  userId: string,
): Promise<void> {
  const { data, error } = await supabase
    .from("chat_threads")
    .select("id")
    .eq("id", threadId)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw error;
  if (!data) throw new Error("Chat thread not found.");
}

export async function insertChatMessage(
  supabase: SupabaseClient,
  message: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const { data, error } = await supabase
    .from("chat_messages")
    .insert(message)
    .select()
    .single();
  if (error) throw error;
  if (!data) throw new Error("Chat message was not saved.");
  return data as Record<string, unknown>;
}
