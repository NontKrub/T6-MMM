import { repetitionInsights } from "../_shared/domain.ts";
import { handleOptions, jsonResponse } from "../_shared/http.ts";
import { requireUser } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { supabase } = await requireUser(req);
    const since = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString();
    const { data, error } = await supabase.from("wear_events")
      .select("style,colors,worn_at")
      .gte("worn_at", since)
      .order("worn_at", { ascending: false });
    if (error) throw error;

    return jsonResponse(
      repetitionInsights(
        (data ?? []) as Array<{ style: string | null; colors: string[]; worn_at: string }>,
      ),
    );
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : "Unknown error" }, 500);
  }
});
