import { handleOptions, jsonResponse, readJson } from "../_shared/http.ts";
import { requireUser } from "../_shared/supabase.ts";

type Body = { latitude: number; longitude: number };

const weatherCodes: Record<number, string> = {
  0: "clear",
  1: "mainly clear",
  2: "partly cloudy",
  3: "cloudy",
  45: "fog",
  48: "fog",
  51: "drizzle",
  53: "drizzle",
  55: "drizzle",
  56: "freezing drizzle",
  57: "freezing drizzle",
  61: "rain",
  63: "rain",
  65: "heavy rain",
  66: "freezing rain",
  67: "freezing rain",
  71: "snow",
  73: "snow",
  75: "heavy snow",
  77: "snow",
  80: "rain showers",
  81: "rain showers",
  82: "heavy rain showers",
  85: "snow showers",
  86: "heavy snow showers",
  95: "thunderstorm",
  96: "thunderstorm",
  99: "thunderstorm",
};

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    await requireUser(req);
    const { latitude, longitude } = await readJson<Body>(req);
    if (typeof latitude !== "number" || typeof longitude !== "number") {
      return jsonResponse({
        error: "latitude and longitude are required numbers.",
      }, 400);
    }

    const baseUrl = Deno.env.get("WEATHER_API_URL") ??
      "https://api.open-meteo.com/v1/forecast";
    const url = new URL(baseUrl);
    url.searchParams.set("latitude", String(latitude));
    url.searchParams.set("longitude", String(longitude));
    url.searchParams.set(
      "current",
      [
        "temperature_2m",
        "relative_humidity_2m",
        "precipitation",
        "rain",
        "weather_code",
        "wind_speed_10m",
      ].join(","),
    );
    url.searchParams.set("wind_speed_unit", "ms");
    url.searchParams.set("timezone", "auto");

    const response = await fetch(url);
    const payload = await response.json();
    if (!response.ok) {
      return jsonResponse({
        error: payload?.reason ?? "Weather request failed.",
      }, 502);
    }

    const current = payload?.current ?? {};
    const temp = Number(current.temperature_2m);
    const wind = Number(current.wind_speed_10m ?? 0);
    const precipitation = Number(current.precipitation ?? 0);
    const rainAmount = Number(current.rain ?? 0);
    const weatherCode = Number(current.weather_code ?? 0);
    const condition = weatherCodes[weatherCode] ?? "clear";
    const rain = precipitation > 0 || rainAmount > 0 ||
      condition.includes("rain") ||
      condition.includes("drizzle") ||
      condition.includes("thunderstorm");
    const temperatureBand = temp >= 30
      ? "hot"
      : temp >= 22
      ? "warm"
      : temp >= 14
      ? "mild"
      : "cold";

    return jsonResponse({
      temperature_c: temp,
      temperature_band: temperatureBand,
      condition,
      rain,
      windy: wind >= 8,
      humidity: current.relative_humidity_2m ?? null,
      outfit_notes: {
        avoid: rain ? ["suede shoes", "delicate fabrics"] : [],
        prefer: [
          temperatureBand === "hot" ? "breathable fabrics" : null,
          rain ? "water-resistant outerwear" : null,
          wind >= 8 ? "secure layers" : null,
        ].filter(Boolean),
      },
    });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unknown error",
    }, 500);
  }
});
