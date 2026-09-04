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
  insertChatMessage,
  updateChatThreadTitleBestEffort,
} from "./fashion_chat.ts";

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
  const client = endpointClient(insertRoles);
  const dependencies: Partial<FashionChatDependencies> = {
    requireUser: async () => ({
      supabase: client,
      userId: "user-a",
    }),
    hasAiConsent: async () => true,
    openAiJson: async () => {
      aiCalls++;
      return { reply: "Try the navy top.", title: "Navy top" };
    },
  };

  const response = await handleFashionChat(
    new Request("https://example.test/fashion-chat", {
      method: "POST",
      body: JSON.stringify({
        thread_id: "thread-a",
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
});

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
            return {
              select() {
                return {
                  single: async () => ({
                    data: { id: "message-id", ...message },
                    error: null,
                  }),
                };
              },
            };
          },
          select() {
            return {
              eq() {
                return {
                  order() {
                    return {
                      limit: async () => ({ data: [], error: null }),
                    };
                  },
                };
              },
            };
          },
        };
      }
      if (table === "profiles") {
        return {
          select() {
            return {
              eq() {
                return {
                  single: async () => ({ data: { id: "user-a" }, error: null }),
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
