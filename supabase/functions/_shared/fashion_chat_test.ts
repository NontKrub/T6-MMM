import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import type { SupabaseClient } from "./supabase.ts";
import {
  type FashionChatDependencies,
  handleFashionChat,
} from "../fashion-chat/index.ts";
import {
  assertChatThreadOwner,
  buildFashionChatAiContext,
  insertChatMessage,
  updateChatThreadTitleBestEffort,
} from "./fashion_chat.ts";

Deno.test("Fashion Chat AI context includes only the approved style profile", () => {
  const context = buildFashionChatAiContext({
    userMessage: "What is my color season?",
    profile: {
      color_season: "spring",
      display_name: "Private name",
      birth_date: "2000-01-01",
      avatar_url: "https://example.test/avatar.png",
      body_shape: "hourglass",
      skin_tone_index: 2,
      hair_color_index: 3,
      hair_style_index: 4,
      brand_tier: 5,
    },
    wardrobe: [{ name: "Blue shirt", category: "top" }],
    recentMessages: [{ role: "assistant", content: "Earlier advice" }],
  });

  assertEquals(context, {
    user_message: "What is my color season?",
    style_profile: { color_season: "spring" },
    wardrobe: [{ name: "Blue shirt", category: "top" }],
    recent_messages: [{ role: "assistant", content: "Earlier advice" }],
  });
  const serialized = JSON.stringify(context);
  for (const key of [
    "birth_date",
    "birth_weekday",
    "display_name",
    "avatar_url",
    "body_shape",
    "skin_tone_index",
    "hair_color_index",
    "hair_style_index",
    "brand_tier",
  ]) {
    assertEquals(serialized.includes(key), false, `${key} is not sent to AI`);
  }
});

Deno.test("a failed user-message insert stops the chat turn before AI", async () => {
  let aiCalls = 0;
  const client = fakeClient({ insertError: new Error("message write failed") });

  await assertRejects(async () => {
    await insertChatMessage(client, {
      thread_id: "thread-a",
      user_id: "user-a",
      role: "user",
      content: "What should I wear?",
    });
    aiCalls++;
  }, Error);

  assertEquals(aiCalls, 0);
});

Deno.test("a foreign thread is rejected before a chat turn can run", async () => {
  let aiCalls = 0;
  const client = fakeClient({ thread: null });

  await assertRejects(async () => {
    await assertChatThreadOwner(client, "thread-b", "user-a");
    aiCalls++;
  }, Error);

  assertEquals(aiCalls, 0);
});

Deno.test("a title update failure does not fail an already-saved assistant reply", async () => {
  const filters: string[] = [];
  const client = {
    from(table: string) {
      if (table !== "chat_threads") throw new Error("unexpected table");
      return {
        update(values: Record<string, unknown>) {
          if (values.title !== "A better title") throw new Error("bad title");
          return {
            eq(column: string, value: string) {
              filters.push(`${column}=${value}`);
              return {
                eq(secondColumn: string, secondValue: string) {
                  filters.push(`${secondColumn}=${secondValue}`);
                  return Promise.resolve({
                    error: new Error("title update failed"),
                  });
                },
              };
            },
          };
        },
      };
    },
  } as unknown as SupabaseClient;

  await updateChatThreadTitleBestEffort(
    client,
    "thread-a",
    "user-a",
    "A better title",
  );
  assertEquals(filters, ["id=thread-a", "user_id=user-a"]);
});

Deno.test("the chat endpoint succeeds when title update fails after assistant persistence", async () => {
  const insertRoles: string[] = [];
  let aiCalls = 0;
  let aiInput: Record<string, unknown> | null = null;
  const client = endpointClient(insertRoles);
  const dependencies: Partial<FashionChatDependencies> = {
    requireUser: async () => ({
      supabase: client,
      userId: "user-a",
    }),
    hasAiConsent: async () => true,
    openAiJson: async (request) => {
      aiCalls++;
      const content = (request as { input: unknown[] }).input[0] as {
        content: Array<{ text: string }>;
      };
      aiInput = JSON.parse(content.content[0].text) as Record<string, unknown>;
      return { reply: "Try the navy top.", title: "Navy top" };
    },
  };

  const response = await handleFashionChat(
    new Request("https://example.test/fashion-chat", {
      method: "POST",
      body: JSON.stringify({
        thread_id: "thread-a",
        turn_id: "f6b43a8e-1328-4b58-94a1-568e65ec6f42",
        message: "What should I wear?",
      }),
      headers: { "Content-Type": "application/json" },
    }),
    dependencies,
  );

  assertEquals(response.status, 200);
  assertEquals(aiCalls, 1);
  assertEquals(insertRoles, ["user", "assistant"]);
  assertEquals((await response.json()).thread_id, "thread-a");
  assertEquals(aiInput, {
    user_message: "What should I wear?",
    style_profile: { color_season: "spring" },
    wardrobe: [],
    recent_messages: [],
  });
});

Deno.test("a completed chat turn is returned without a second AI call", async () => {
  const insertRoles: string[] = [];
  let aiCalls = 0;
  const client = endpointClient(insertRoles);
  const dependencies: Partial<FashionChatDependencies> = {
    requireUser: async () => ({ supabase: client, userId: "user-a" }),
    hasAiConsent: async () => true,
    openAiJson: async () => {
      aiCalls++;
      return { reply: "Try the navy top.", title: "Navy top" };
    },
  };
  const body = JSON.stringify({
    thread_id: "thread-a",
    turn_id: "f6b43a8e-1328-4b58-94a1-568e65ec6f42",
    message: "What should I wear?",
  });

  const first = await handleFashionChat(requestWithBody(body), dependencies);
  const second = await handleFashionChat(requestWithBody(body), dependencies);

  assertEquals(first.status, 200);
  assertEquals(second.status, 200);
  assertEquals(aiCalls, 1);
  assertEquals(insertRoles, ["user", "assistant"]);
});

Deno.test("a reused chat turn with different content is rejected", async () => {
  const insertRoles: string[] = [];
  const client = endpointClient(insertRoles);
  const dependencies: Partial<FashionChatDependencies> = {
    requireUser: async () => ({ supabase: client, userId: "user-a" }),
    hasAiConsent: async () => true,
    openAiJson: async () => ({ reply: "Try the navy top.", title: "Navy top" }),
  };
  const turnId = "f6b43a8e-1328-4b58-94a1-568e65ec6f42";

  await handleFashionChat(
    requestWithBody(JSON.stringify({
      thread_id: "thread-a",
      turn_id: turnId,
      message: "What should I wear?",
    })),
    dependencies,
  );
  const response = await handleFashionChat(
    requestWithBody(JSON.stringify({
      thread_id: "thread-a",
      turn_id: turnId,
      message: "Something different",
    })),
    dependencies,
  );

  assertEquals(response.status, 409);
  assertEquals((await response.json()).code, "chat_turn_conflict");
  assertEquals(insertRoles, ["user", "assistant"]);
});

function requestWithBody(body: string): Request {
  return new Request("https://example.test/fashion-chat", {
    method: "POST",
    body,
    headers: { "Content-Type": "application/json" },
  });
}

function fakeClient(options: {
  insertError?: Error;
  thread?: Record<string, unknown> | null;
}): SupabaseClient {
  return {
    from(table: string) {
      if (table === "chat_threads") {
        return {
          select() {
            return {
              eq() {
                return {
                  eq() {
                    return {
                      maybeSingle: async () => ({
                        data: options.thread,
                        error: null,
                      }),
                    };
                  },
                };
              },
            };
          },
        };
      }
      return {
        insert() {
          return {
            select() {
              return {
                single: async () => ({
                  data: null,
                  error: options.insertError ?? null,
                }),
              };
            },
          };
        },
      };
    },
  } as unknown as SupabaseClient;
}

function endpointClient(insertRoles: string[]): SupabaseClient {
  const storedMessages: Record<string, unknown>[] = [];
  return {
    from(table: string) {
      if (table === "chat_threads") {
        return {
          select() {
            return {
              eq() {
                return {
                  eq() {
                    return {
                      maybeSingle: async () => ({
                        data: { id: "thread-a" },
                        error: null,
                      }),
                    };
                  },
                };
              },
            };
          },
          update() {
            return {
              eq() {
                return {
                  eq: async () => ({
                    error: new Error("title update failed"),
                  }),
                };
              },
            };
          },
        };
      }
      if (table === "chat_messages") {
        return {
          insert(message: Record<string, unknown>) {
            insertRoles.push(String(message.role));
            const saved = {
              id: `message-${insertRoles.length}`,
              ...message,
            };
            storedMessages.push(saved);
            return {
              select() {
                return {
                  single: async () => ({
                    data: saved,
                    error: null,
                  }),
                };
              },
            };
          },
          select() {
            const filters = new Map<string, string>();
            const query = {
              eq(column: string, value: string) {
                filters.set(column, value);
                return query;
              },
              maybeSingle: async () => ({
                data: storedMessages.find((message) =>
                  [...filters].every(([column, value]) =>
                    message[column] === value
                  )
                ) ?? null,
                error: null,
              }),
              order() {
                return query;
              },
              limit: async () => ({ data: storedMessages, error: null }),
            };
            return query;
          },
        };
      }
      if (table === "profiles") {
        return {
          select() {
            return {
              eq() {
                return {
                  maybeSingle: async () => ({
                    data: { color_season: "spring" },
                    error: null,
                  }),
                };
              },
            };
          },
        };
      }
      if (table === "clothing_items") {
        return {
          select() {
            return {
              is() {
                return {
                  limit: async () => ({ data: [], error: null }),
                };
              },
            };
          },
        };
      }
      throw new Error(`unexpected table: ${table}`);
    },
  } as unknown as SupabaseClient;
}
