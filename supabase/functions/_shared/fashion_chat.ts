import type { SupabaseClient } from "./supabase.ts";

export class FashionChatError extends Error {
  constructor(
    public readonly code: string,
    public readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = "FashionChatError";
  }
}

export type StoredChatMessage = Record<string, unknown> & {
  id: string;
  thread_id: string;
  user_id: string;
  role: "user" | "assistant";
  content: string;
  turn_id?: string | null;
};

export function isChatTurnId(value: unknown): value is string {
  return typeof value === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(value);
}

export function buildFashionChatAiContext({
  userMessage,
  profile,
  wardrobe,
  recentMessages,
}: {
  userMessage: string;
  profile: Record<string, unknown> | null;
  wardrobe: unknown[];
  recentMessages: unknown[];
}): Record<string, unknown> {
  return {
    user_message: userMessage,
    style_profile: {
      color_season: typeof profile?.color_season === "string"
        ? profile.color_season
        : null,
    },
    wardrobe,
    recent_messages: recentMessages,
  };
}

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
  if (!data) {
    throw new FashionChatError(
      "chat_thread_not_found",
      404,
      "The requested chat thread was not found.",
    );
  }
}

export async function findChatMessageByTurn(
  supabase: SupabaseClient,
  userId: string,
  turnId: string,
  role: "user" | "assistant",
): Promise<StoredChatMessage | null> {
  const { data, error } = await supabase.from("chat_messages")
    .select("id,thread_id,user_id,role,content,turn_id,created_at")
    .eq("user_id", userId)
    .eq("turn_id", turnId)
    .eq("role", role)
    .maybeSingle();
  if (error) throw error;
  return data as StoredChatMessage | null;
}

export async function insertChatMessage(
  supabase: SupabaseClient,
  message: Record<string, unknown>,
): Promise<StoredChatMessage> {
  const { data, error } = await supabase
    .from("chat_messages")
    .insert(message)
    .select()
    .single();
  if (error) throw error;
  if (!data) throw new Error("Chat message was not saved.");
  return data as StoredChatMessage;
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
