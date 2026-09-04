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

export async function updateChatThreadTitleBestEffort(
  supabase: SupabaseClient,
  threadId: string,
  userId: string,
  title: string,
): Promise<void> {
  try {
    const { error } = await supabase
      .from("chat_threads")
      .update({ title, updated_at: new Date().toISOString() })
      .eq("id", threadId)
      .eq("user_id", userId);
    if (error) throw error;
  } catch (error) {
    console.error(
      "Fashion chat title update failed.",
      error instanceof Error ? error.message : "Unknown title update error.",
    );
  }
}
