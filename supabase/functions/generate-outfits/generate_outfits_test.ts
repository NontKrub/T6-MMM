import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  handleGenerateOutfits,
  type GenerateOutfitsDependencies,
} from "./index.ts";
import type { SupabaseClient } from "../_shared/supabase.ts";

for (const table of [
  "profiles",
  "style_preferences",
  "clothing_items",
  "wear_events",
  "outfit_preference_events",
]) {
  Deno.test(`a ${table} context failure stops outfit generation`, async () => {
    let aiCalls = 0;
    let rpcCalls = 0;
    const client = contextClient(table, () => rpcCalls++);
    const dependencies: Partial<GenerateOutfitsDependencies> = {
      requireUser: async () => ({ supabase: client, userId: "user-a" }),
      hasAiConsent: async () => true,
      openAiJson: async () => {
        aiCalls++;
        return { outfits: [] };
      },
    };

    const response = await handleGenerateOutfits(
      new Request("https://example.test/generate-outfits", {
        method: "POST",
        body: JSON.stringify({}),
        headers: { "Content-Type": "application/json" },
      }),
      dependencies,
    );

    assertEquals(response.status, 500);
    assertEquals((await response.json()).code, "outfit_context_unavailable");
    assertEquals(aiCalls, 0);
    assertEquals(rpcCalls, 0);
  });
}

Deno.test("an empty wardrobe remains a product response, not a context error", async () => {
  let aiCalls = 0;
  const response = await handleGenerateOutfits(
    new Request("https://example.test/generate-outfits", {
      method: "POST",
      body: JSON.stringify({}),
      headers: { "Content-Type": "application/json" },
    }),
    {
      requireUser: async () => ({
        supabase: contextClient("", () => undefined),
        userId: "user-a",
      }),
      hasAiConsent: async () => true,
      openAiJson: async () => {
        aiCalls++;
        return { outfits: [] };
      },
    },
  );

  assertEquals(response.status, 422);
  assertEquals(aiCalls, 0);
});

function contextClient(
  failedTable: string,
  rpcCalled: () => void,
): SupabaseClient {
  const result = (table: string) => ({
    data: table === failedTable ? null : [],
    error: table === failedTable ? new Error(`${table} failed`) : null,
  });
  return {
    from(table: string) {
      if (table === "profiles") {
        return {
          select() {
            return {
              eq() {
                return { maybeSingle: async () => result(table) };
              },
            };
          },
        };
      }
      if (table === "style_preferences") {
        return { select: async () => result(table) };
      }
      if (table === "clothing_items") {
        return {
          select() {
            return {
              is() {
                return { order: async () => result(table) };
              },
            };
          },
        };
      }
      return {
        select() {
          return {
            order() {
              return { limit: async () => result(table) };
            },
          };
        },
      };
    },
    rpc() {
      rpcCalled();
      return Promise.resolve({ data: null, error: null });
    },
  } as unknown as SupabaseClient;
}
