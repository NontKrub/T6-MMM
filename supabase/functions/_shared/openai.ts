type ResponseFormat = {
  type: "json_schema";
  name: string;
  schema: Record<string, unknown>;
  strict?: boolean;
};

type ResponsesContentPart = {
  type: string;
  text?: string;
  image_url?: string;
};

type ResponsesMessage = {
  role: string;
  content: ResponsesContentPart[];
};

export async function openAiJson<T>(params: {
  model?: string;
  instructions: string;
  input: unknown;
  responseFormat: ResponseFormat;
  maxOutputTokens?: number;
}): Promise<T> {
  const openRouterApiKey = Deno.env.get("OPENROUTER_API_KEY");
  if (openRouterApiKey) {
    return openRouterJson<T>(params, openRouterApiKey);
  }

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    throw new Error("OPENROUTER_API_KEY or OPENAI_API_KEY is not configured.");
  }

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: params.model ?? Deno.env.get("OPENAI_MODEL") ?? "gpt-4.1-mini",
      instructions: params.instructions,
      input: params.input,
      text: { format: params.responseFormat },
      max_output_tokens: params.maxOutputTokens ?? 900,
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload?.error?.message ?? "OpenAI request failed.");
  }

  const text = payload.output_text ??
    payload.output?.flatMap((item: { content?: Array<{ text?: string }> }) =>
      item.content?.map((content) => content.text).filter(Boolean) ?? []
    ).join("\n");

  if (!text) {
    throw new Error("OpenAI returned no text output.");
  }

  return JSON.parse(text) as T;
}

async function openRouterJson<T>(
  params: {
    model?: string;
    instructions: string;
    input: unknown;
    responseFormat: ResponseFormat;
    maxOutputTokens?: number;
  },
  apiKey: string,
): Promise<T> {
  const response = await fetch(
    "https://openrouter.ai/api/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
        "X-Title": "Wardrobly",
      },
      body: JSON.stringify({
        model: params.model ?? Deno.env.get("OPENROUTER_MODEL") ??
          "openai/gpt-4.1-mini",
        messages: [
          { role: "system", content: params.instructions },
          ...toOpenRouterMessages(params.input),
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: params.responseFormat.name,
            strict: params.responseFormat.strict ?? true,
            schema: params.responseFormat.schema,
          },
        },
        max_tokens: params.maxOutputTokens ?? 900,
      }),
    },
  );

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload?.error?.message ?? "OpenRouter request failed.");
  }

  const content = payload?.choices?.[0]?.message?.content;
  const text = typeof content === "string"
    ? content
    : Array.isArray(content)
    ? content.map((part) => part?.text).filter(Boolean).join("\n")
    : "";

  if (!text) {
    throw new Error("OpenRouter returned no text output.");
  }

  return JSON.parse(stripJsonFence(text)) as T;
}

function toOpenRouterMessages(input: unknown) {
  if (!Array.isArray(input)) {
    return [{ role: "user", content: String(input) }];
  }

  return (input as ResponsesMessage[]).map((message) => ({
    role: message.role,
    content: message.content.map((part) => {
      if (part.type === "input_image") {
        return {
          type: "image_url",
          image_url: { url: part.image_url },
        };
      }

      return {
        type: "text",
        text: part.text ?? "",
      };
    }),
  }));
}

function stripJsonFence(text: string) {
  return text.trim().replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/i, "");
}

export const clothingAnalysisSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "category",
    "suggested_name",
    "dominant_colors",
    "primary_color",
    "tags",
    "attributes",
    "confidence",
  ],
  properties: {
    category: {
      type: "string",
      enum: ["hat", "top", "pants", "shoes", "accessory"],
    },
    suggested_name: { type: "string" },
    dominant_colors: {
      type: "array",
      items: { type: "string" },
      maxItems: 5,
    },
    primary_color: { type: "string" },
    tags: {
      type: "array",
      items: { type: "string" },
      maxItems: 8,
    },
    attributes: {
      type: "object",
      additionalProperties: {
        type: ["string", "number", "boolean", "array", "object", "null"],
      },
    },
    confidence: { type: "number", minimum: 0, maximum: 1 },
  },
};

export const outfitSchema = {
  type: "object",
  additionalProperties: false,
  required: ["outfits"],
  properties: {
    outfits: {
      type: "array",
      minItems: 0,
      maxItems: 5,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "item_ids", "style", "reason", "score"],
        properties: {
          name: { type: "string" },
          item_ids: { type: "array", items: { type: "string" }, minItems: 1 },
          style: { type: "string" },
          reason: { type: "string" },
          score: { type: "number", minimum: 0, maximum: 100 },
        },
      },
    },
  },
};

export const recommendationsSchema = {
  type: "object",
  additionalProperties: false,
  required: ["recommendations"],
  properties: {
    recommendations: {
      type: "array",
      maxItems: 8,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["category", "title", "reason", "suggestion", "priority"],
        properties: {
          category: {
            type: "string",
            enum: ["hat", "top", "pants", "shoes", "accessory"],
          },
          title: { type: "string" },
          reason: { type: "string" },
          suggestion: { type: "string" },
          priority: { type: "string" },
        },
      },
    },
  },
};

export const chatSchema = {
  type: "object",
  additionalProperties: false,
  required: ["reply", "title"],
  properties: {
    reply: { type: "string" },
    title: { type: "string" },
  },
};
