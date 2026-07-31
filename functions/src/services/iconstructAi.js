/**
 * Shared iConstruct AI scope + Gemini helpers.
 * AI must only support material estimation / canvassing planning — not general chat.
 */
const logger = require("firebase-functions/logger");
const { HttpsError } = require("firebase-functions/v2/https");

const ICONSTRUCT_SYSTEM_SCOPE = `You are the iConstruct AI Material Consultant ONLY.

iConstruct is a Smart Material Estimator and Bidding Process Support System for builders.
Your ONLY job is the planning / pre-procurement phase:
1) Help builders describe material wants for a renovation estimate
2) Suggest basic, hardware-store essential materials (concrete names a builder can buy)
3) Support building an essential Bill of Materials (BOM) for canvassing / requesting quotations

STRICT OUT OF SCOPE — refuse and redirect:
- General knowledge, homework, coding, entertainment, medical/legal advice
- On-site construction management, labor scheduling, crews, progress logging
- Acting as a shop catalog, price guarantee, or ordering system
- Deciding for the user — you SUGGEST options; the builder chooses
- Topics unrelated to renovation materials for this estimate

If the user goes off-topic, briefly say you can only help with iConstruct material planning for their renovation estimate, then invite them back to materials/ideas/area/BOM.

Philippines hardware-store context. Prefer concrete names like "Ceramic floor tiles", "Tile adhesive", "Toilet bowl set" — never vague labels like "essential materials" or "install supplies".`;

function resolveGeminiKey(secretRef) {
  try {
    const v = secretRef.value();
    if (v && String(v).trim()) return String(v).trim();
  } catch (_) {
    // ignore
  }
  const env = process.env.GEMINI_API_KEY;
  return env && String(env).trim() ? String(env).trim() : null;
}

const GEMINI_MODELS = [
  "gemini-3.5-flash-lite",
  "gemini-3.6-flash",
  "gemini-2.5-flash-lite",
  "gemini-flash-latest",
];

async function callGeminiJson(apiKey, { system, user, temperature = 0.3 }) {
  const { GoogleGenAI } = require("@google/genai");
  const ai = new GoogleGenAI({ apiKey });
  const contents = `${system}\n\n---\n\nUSER REQUEST:\n${user}`;

  let lastError = null;
  for (const model of GEMINI_MODELS) {
    try {
      const response = await ai.models.generateContent({
        model,
        contents,
        config: {
          responseMimeType: "application/json",
          temperature,
        },
      });
      const text = response.text || "";
      try {
        return JSON.parse(text);
      } catch (parseError) {
        logger.error("Failed to parse Gemini JSON", { model, text, parseError });
        throw new HttpsError("internal", "AI returned invalid data format.");
      }
    } catch (error) {
      lastError = error;
      const msg = String(error?.message || error || "");
      const unavailable =
        error?.status === 404 ||
        msg.includes("NOT_FOUND") ||
        msg.includes("no longer available") ||
        msg.includes("not found");
      if (unavailable) {
        logger.warn(`Gemini model unavailable, trying next: ${model}`, { msg });
        continue;
      }
      throw error;
    }
  }

  logger.error("All Gemini models failed", { lastError });
  throw lastError || new Error("No Gemini model available");
}

async function callOpenAiJson(apiKey, { system, user, temperature = 0.3 }) {
  const axios = require("axios");
  const response = await axios.post(
    "https://api.openai.com/v1/chat/completions",
    {
      model: "gpt-4o-mini",
      temperature,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: system },
        { role: "user", content: user },
      ],
    },
    {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      timeout: 60000,
    }
  );
  const text = response.data?.choices?.[0]?.message?.content || "";
  return JSON.parse(text);
}

async function runMaterialConsult({
  projectType = "General Renovation",
  userMessage = "",
  style = "",
  areaSqm = 0,
  ideaLog = [],
  selectedMaterials = [],
  projectNotes = "",
  geminiSecret,
}) {
  const message = String(userMessage || "").trim();
  if (!message) {
    throw new HttpsError("invalid-argument", "Message is required.");
  }

  const userPrompt = `Project type: ${projectType}
Style notes: ${style || "(not set)"}
Area (sqm): ${areaSqm || "(not set)"}
Materials already chosen by builder: ${
    Array.isArray(selectedMaterials) && selectedMaterials.length
      ? selectedMaterials.join(", ")
      : "(none yet)"
  }
Earlier ideas from builder:
${
  Array.isArray(ideaLog) && ideaLog.length
    ? ideaLog.map((e) => "- " + e).join("\n")
    : "(none)"
}
Estimate notes: ${projectNotes || "(none)"}

Latest builder message:
${message}

Respond ONLY as JSON with this exact shape:
{
  "inScope": true,
  "reply": "Short helpful message. Suggest options; do not decide for the builder. If off-topic, set inScope false and redirect to iConstruct material planning.",
  "suggestions": ["Concrete material names only", "Max 6 items", "Empty array if none or off-topic"]
}

Rules for suggestions:
- Only basic essential materials for THIS renovation estimate
- Empty suggestions if the message is off-topic or not about materials
- Never invent a full forced package unless the builder asked for ideas`;

  const geminiKey = resolveGeminiKey(geminiSecret);
  const openaiKey = process.env.OPENAI_API_KEY;

  let parsed = null;
  if (geminiKey) {
    try {
      parsed = await callGeminiJson(geminiKey, {
        system: ICONSTRUCT_SYSTEM_SCOPE,
        user: userPrompt,
        temperature: 0.35,
      });
    } catch (error) {
      logger.error("runMaterialConsult Gemini failed:", error);
    }
  }

  if (!parsed && openaiKey && String(openaiKey).trim()) {
    try {
      parsed = await callOpenAiJson(String(openaiKey).trim(), {
        system: ICONSTRUCT_SYSTEM_SCOPE,
        user: userPrompt,
        temperature: 0.35,
      });
    } catch (error) {
      logger.error("runMaterialConsult OpenAI failed:", error);
    }
  }

  if (!parsed) {
    throw new HttpsError(
      "internal",
      "iConstruct AI is currently unavailable. Set GEMINI_API_KEY."
    );
  }

  const suggestions = Array.isArray(parsed.suggestions)
    ? parsed.suggestions
        .map((s) => String(s || "").trim())
        .filter(Boolean)
        .slice(0, 8)
    : [];

  const inScope = parsed.inScope !== false;
  let reply = String(parsed.reply || "").trim();
  if (!reply) {
    reply = inScope
      ? "Tell me more about the materials you want for this estimate — I only suggest options; you decide."
      : "I can only help with iConstruct material planning for your renovation estimate. Describe materials, finishes, fixtures, or area — or open Templates for a ready package.";
  }

  return {
    success: true,
    inScope,
    reply,
    suggestions: inScope ? suggestions : [],
    provider: geminiKey ? "gemini" : "openai",
  };
}

module.exports = {
  ICONSTRUCT_SYSTEM_SCOPE,
  resolveGeminiKey,
  callGeminiJson,
  callOpenAiJson,
  runMaterialConsult,
};
