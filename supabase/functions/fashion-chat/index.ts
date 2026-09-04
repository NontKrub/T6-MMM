import { handleOptions, jsonResponse, readJson } from "../_shared/http.ts";
import { hasAiConsent } from "../_shared/ai_consent.ts";
import {
  assertChatThreadOwner,
  buildFashionChatAiContext,
  FashionChatError,
  findChatMessageByTurn,
  insertChatMessage,
  isChatTurnId,
  updateChatThreadTitleBestEffort,
} from "../_shared/fashion_chat.ts";
import { chatSchema, openAiJson } from "../_shared/openai.ts";
import { requireUser } from "../_shared/supabase.ts";

type Body = {
  message: string;
  thread_id?: string;
  turn_id?: string;
};

type ChatAiRequest = {
  instructions: string;
  input: unknown;
  responseFormat: {
    type: "json_schema";
    name: string;
    schema: Record<string, unknown>;
    strict: boolean;
  };
};

type ChatAiCaller = (
  params: ChatAiRequest,
) => Promise<{ reply: string; title: string }>;

export type FashionChatDependencies = {
  requireUser: typeof requireUser;
  hasAiConsent: typeof hasAiConsent;
  openAiJson: ChatAiCaller;
};

const defaultDependencies: FashionChatDependencies = {
  requireUser,
  hasAiConsent,
  openAiJson: (params) => openAiJson<{ reply: string; title: string }>(params),
};

if (import.meta.main) {
  Deno.serve((req) => handleFashionChat(req));
}

export async function handleFashionChat(
  req: Request,
  overrides: Partial<FashionChatDependencies> = {},
): Promise<Response> {
  const dependencies: FashionChatDependencies = {
    ...defaultDependencies,
    ...overrides,
  };
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { supabase, userId } = await dependencies.requireUser(req);
    if (!await dependencies.hasAiConsent(supabase, userId)) {
      return jsonResponse({
        error: "Third-party AI consent is required for fashion chat.",
        code: "ai_consent_required",
      }, 403);
    }
    const body = await readJson<Body>(req);
    const message = body.message?.trim();
    if (!message) {
      return jsonResponse({ error: "message is required." }, 400);
    }
    if (body.turn_id !== undefined && !isChatTurnId(body.turn_id)) {
      return jsonResponse({
        error: "turn_id must be a UUID.",
        code: "chat_turn_invalid",
      }, 400);
    }

    let threadId: string | undefined = body.thread_id;
    if (threadId) {
      await assertChatThreadOwner(supabase, threadId, userId);
    }

    let existingUserMessage = body.turn_id
      ? await findChatMessageByTurn(supabase, userId, body.turn_id, "user")
      : null;
    if (existingUserMessage) {
      if (existingUserMessage.content !== message) {
        return jsonResponse({
          error: "This chat turn has different message content.",
          code: "chat_turn_conflict",
        }, 409);
      }
      if (threadId && threadId !== existingUserMessage.thread_id) {
        return jsonResponse({
          error: "This chat turn belongs to a different thread.",
          code: "chat_turn_conflict",
        }, 409);
      }
      threadId = existingUserMessage.thread_id;
      const existingAssistantMessage = await findChatMessageByTurn(
        supabase,
        userId,
        body.turn_id!,
        "assistant",
      );
      if (existingAssistantMessage) {
        return jsonResponse({
          thread_id: threadId,
          message: existingAssistantMessage,
        });
      }
    }

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

    if (!existingUserMessage) {
      try {
        existingUserMessage = await insertChatMessage(supabase, {
          thread_id: threadId,
          user_id: userId,
          role: "user",
          content: message,
          ...(body.turn_id ? { turn_id: body.turn_id } : {}),
        });
      } catch (error) {
        if (!body.turn_id || !isUniqueViolation(error)) throw error;
        existingUserMessage = await findChatMessageByTurn(
          supabase,
          userId,
          body.turn_id,
          "user",
        );
        if (!existingUserMessage) throw error;
        if (existingUserMessage.content !== message) {
          return jsonResponse({
            error: "This chat turn has different message content.",
            code: "chat_turn_conflict",
          }, 409);
        }
        threadId = existingUserMessage.thread_id;
      }
    }

    const [profileResult, wardrobeResult, recentMessagesResult] = await Promise
      .all([
        supabase.from("profiles")
          .select("color_season")
          .eq("id", userId)
          .maybeSingle(),
        supabase.from("clothing_items")
          .select("name,brand,category,tags,dominant_colors,primary_color")
          .is("archived_at", null)
          .limit(60),
        supabase.from("chat_messages")
          .select("id,role,content,turn_id,created_at")
          .eq("thread_id", threadId)
          .order("created_at", { ascending: false })
          .limit(10),
      ]);
    if (profileResult.error) throw profileResult.error;
    if (wardrobeResult.error) throw wardrobeResult.error;
    if (recentMessagesResult.error) throw recentMessagesResult.error;

    const result = await dependencies.openAiJson({
      instructions:
        "You are Mix Match Mood's fashion assistant. Answer conversationally, identify style names when asked, and use the user's wardrobe context only when relevant. Keep advice concise and actionable.",
      input: [{
        role: "user",
        content: [{
          type: "input_text",
          text: JSON.stringify(buildFashionChatAiContext({
            userMessage: message,
            profile: profileResult.data,
            wardrobe: wardrobeResult.data ?? [],
            recentMessages: (recentMessagesResult.data ?? [])
              .filter((row) => row.id !== existingUserMessage!.id)
              .reverse(),
          })),
        }],
      }],
      responseFormat: {
        type: "json_schema",
        name: "fashion_chat_reply",
        schema: chatSchema,
        strict: true,
      },
    });

    let assistantMessage;
    try {
      assistantMessage = await insertChatMessage(supabase, {
        thread_id: threadId,
        user_id: userId,
        role: "assistant",
        content: result.reply,
        ...(body.turn_id ? { turn_id: body.turn_id } : {}),
      });
    } catch (error) {
      if (!body.turn_id || !isUniqueViolation(error)) throw error;
      const existingAssistantMessage = await findChatMessageByTurn(
        supabase,
        userId,
        body.turn_id,
        "assistant",
      );
      if (!existingAssistantMessage) throw error;
      assistantMessage = existingAssistantMessage;
    }

    await updateChatThreadTitleBestEffort(
      supabase,
      threadId,
      userId,
      result.title,
    );

    return jsonResponse({ thread_id: threadId, message: assistantMessage });
  } catch (error) {
    if (error instanceof FashionChatError) {
      return jsonResponse({ error: error.message, code: error.code }, error.status);
    }
    return jsonResponse({
      error: "Fashion chat is temporarily unavailable.",
      code: "fashion_chat_unavailable",
    }, 500);
  }
}

function isUniqueViolation(error: unknown): boolean {
  return typeof error === "object" && error !== null &&
    "code" in error && (error as { code?: unknown }).code === "23505";
}
