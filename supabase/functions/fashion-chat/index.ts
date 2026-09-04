import { handleOptions, jsonResponse, readJson } from "../_shared/http.ts";
import { hasAiConsent } from "../_shared/ai_consent.ts";
import {
  assertChatThreadOwner,
  insertChatMessage,
  updateChatThreadTitleBestEffort,
} from "../_shared/fashion_chat.ts";
import { chatSchema, openAiJson } from "../_shared/openai.ts";
import { requireUser } from "../_shared/supabase.ts";

type Body = {
  message: string;
  thread_id?: string;
};

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { supabase, userId } = await requireUser(req);
    if (!await hasAiConsent(supabase, userId)) {
      return jsonResponse({
        error: "Third-party AI consent is required for fashion chat.",
        code: "ai_consent_required",
      }, 403);
    }
    const body = await readJson<Body>(req);
    if (!body.message?.trim()) {
      return jsonResponse({ error: "message is required." }, 400);
    }

    let threadId: string | undefined = body.thread_id;
    if (!threadId) {
      const { data: thread, error } = await supabase.from("chat_threads")
        .insert({ user_id: userId, title: "Fashion chat" })
        .select()
        .single();
      if (error) throw error;
      if (!thread) throw new Error("Chat thread was not created.");
      threadId = String(thread.id);
    } else {
      await assertChatThreadOwner(supabase, threadId, userId);
    }

    if (!threadId) {
      return jsonResponse({ error: "Unable to create chat thread." }, 500);
    }

    await insertChatMessage(supabase, {
      thread_id: threadId,
      user_id: userId,
      role: "user",
      content: body.message,
    });

    const [profileResult, wardrobeResult, recentMessagesResult] = await Promise
      .all([
        supabase.from("profiles").select("*").eq("id", userId).single(),
        supabase.from("clothing_items")
          .select("name,brand,category,tags,dominant_colors,primary_color")
          .is("archived_at", null)
          .limit(60),
        supabase.from("chat_messages")
          .select("role,content,created_at")
          .eq("thread_id", threadId)
          .order("created_at", { ascending: false })
          .limit(10),
      ]);
    if (profileResult.error) throw profileResult.error;
    if (wardrobeResult.error) throw wardrobeResult.error;
    if (recentMessagesResult.error) throw recentMessagesResult.error;

    const result = await openAiJson<{ reply: string; title: string }>({
      instructions:
        "You are Mix Match Mood's fashion assistant. Answer conversationally, identify style names when asked, and use the user's wardrobe context only when relevant. Keep advice concise and actionable.",
      input: [{
        role: "user",
        content: [{
          type: "input_text",
          text: JSON.stringify({
            user_message: body.message,
            profile: profileResult.data,
            wardrobe: wardrobeResult.data,
            recent_messages: (recentMessagesResult.data ?? []).reverse(),
          }),
        }],
      }],
      responseFormat: {
        type: "json_schema",
        name: "fashion_chat_reply",
        schema: chatSchema,
        strict: true,
      },
    });

    const assistantMessage = await insertChatMessage(supabase, {
      thread_id: threadId,
      user_id: userId,
      role: "assistant",
      content: result.reply,
    });

    await updateChatThreadTitleBestEffort(
      supabase,
      threadId,
      userId,
      result.title,
    );

    return jsonResponse({ thread_id: threadId, message: assistantMessage });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unknown error",
    }, 500);
  }
});
