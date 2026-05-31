import { luckyColorsFor } from "../_shared/domain.ts";
import { handleOptions, jsonResponse } from "../_shared/http.ts";
import { requireUser } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { supabase, userId } = await requireUser(req);
    const { data: profile, error } = await supabase.from("profiles")
      .select("birth_date,birth_weekday")
      .eq("id", userId)
      .single();
    if (error) throw error;

    const today = new Date();
    const birthDate = typeof profile?.birth_date === "string" ? profile.birth_date : null;
    const birthWeekday = typeof profile?.birth_weekday === "number"
      ? profile.birth_weekday
      : null;

    return jsonResponse({
      date: today.toISOString().slice(0, 10),
      colors: luckyColorsFor(today, birthDate, birthWeekday),
    });
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : "Unknown error" }, 500);
  }
});
