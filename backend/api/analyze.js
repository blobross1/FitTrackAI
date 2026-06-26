/**
 * Fit Track AI — body fat analysis proxy (keeps OpenAI key off the device).
 * Deploy to Vercel: set OPENAI_API_KEY and FITTRACK_API_SECRET in project env vars.
 */

const OPENAI_URL = "https://api.openai.com/v1/chat/completions";
const MODEL = "gpt-4o-mini";

function analysisPrompt(weightKg) {
  const weightLine =
    weightKg != null && !Number.isNaN(weightKg)
      ? `The person weighs ${weightKg} kg. Use this only as weak context — prioritize what you see in the photo.\n\n`
      : "";

  return `${weightLine}You are analyzing one specific fitness/progress photo. Estimate body fat percentage from visible physique only (muscle definition, fat on torso/limbs, vascularity, ab visibility).

Rules:
- body_fat_low and body_fat_high must be numbers between 6 and 45.
- The range should span about 2–4 percentage points.
- Different photos with clearly different leanness MUST get different estimates — do not reuse the same range every time.
- If the image is unclear, still give your best visual estimate and mention uncertainty in feedback.

Also provide brief, constructive feedback about their physique.`;
}

const JSON_SCHEMA = {
  name: "body_fat_analysis",
  strict: true,
  schema: {
    type: "object",
    properties: {
      body_fat_low: { type: "number" },
      body_fat_high: { type: "number" },
      feedback: { type: "string" },
    },
    required: ["body_fat_low", "body_fat_high", "feedback"],
    additionalProperties: false,
  },
};

export default async function handler(req, res) {
  if (req.method === "OPTIONS") {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
    return res.status(204).end();
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const secret = process.env.FITTRACK_API_SECRET;
  const openaiKey = process.env.OPENAI_API_KEY;

  if (!secret || !openaiKey) {
    return res.status(500).json({ error: "Server not configured" });
  }

  const auth = req.headers.authorization || "";
  if (auth !== `Bearer ${secret}`) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const { imageBase64, weightKg } = req.body || {};

  if (!imageBase64 || typeof imageBase64 !== "string" || imageBase64.length > 6_000_000) {
    return res.status(400).json({ error: "Invalid image" });
  }

  const dataUrl = imageBase64.startsWith("data:")
    ? imageBase64
    : `data:image/jpeg;base64,${imageBase64}`;

  const parsedWeight =
    weightKg != null && weightKg !== "" ? Number(weightKg) : null;

  try {
    const openaiRes = await fetch(OPENAI_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: analysisPrompt(parsedWeight) },
              {
                type: "image_url",
                image_url: { url: dataUrl, detail: "high" },
              },
            ],
          },
        ],
        response_format: {
          type: "json_schema",
          json_schema: JSON_SCHEMA,
        },
      }),
    });

    const data = await openaiRes.json();

    if (!openaiRes.ok) {
      const msg = data?.error?.message || JSON.stringify(data);
      return res.status(502).json({ error: msg });
    }

    const content = data?.choices?.[0]?.message?.content;
    if (!content) {
      return res.status(502).json({ error: "Empty model response" });
    }

    const parsed = JSON.parse(content);
    const low = Number(parsed.body_fat_low);
    const high = Number(parsed.body_fat_high);

    if (!Number.isFinite(low) || !Number.isFinite(high)) {
      return res.status(502).json({ error: "Invalid body fat numbers from model" });
    }

    res.setHeader("Access-Control-Allow-Origin", "*");
    return res.status(200).json({
      body_fat_low: low,
      body_fat_high: high,
      feedback: parsed.feedback,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Analysis failed" });
  }
}
