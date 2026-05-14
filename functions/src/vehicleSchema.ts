import { z } from "zod";

/** Zgodne z Gemini prompt + modelem `VehicleType` w Flutter (bez `van`). */
export const vehicleTypeSchema = z.enum([
  "car",
  "motorcycle",
  "truck",
  "bus",
  "aircraft",
  "boat",
  "train",
  "agricultural",
  "construction",
  "military",
  "emergency",
  "bicycle",
  "scooter",
  "other",
  "unknown",
]);

export const geminiVehicleResponseSchema = z.object({
  vehicleType: vehicleTypeSchema,
  brand: z.string().nullable().optional(),
  model: z.string().nullable().optional(),
  generation: z.string().nullable().optional(),
  productionYears: z.string().nullable().optional(),
  possibleEngines: z.array(z.string()).optional().default([]),
  shortDescription: z.string().nullable().optional(),
  confidence: z.number().min(0).max(1),
  sourceLanguage: z.enum(["pl", "en"]),
});

export type GeminiVehicleResponse = z.infer<typeof geminiVehicleResponseSchema>;

/** Pola `vehicle_info` w Firestore — snake_case jak w Flutter `VehicleInfo.toJson`. */
export function toFirestoreVehicleInfo(v: GeminiVehicleResponse): Record<string, unknown> {
  return {
    vehicle_type: v.vehicleType,
    brand: v.brand ?? null,
    model: v.model ?? null,
    generation: v.generation ?? null,
    production_years: v.productionYears ?? null,
    possible_engines: v.possibleEngines ?? [],
    short_description: v.shortDescription ?? null,
    confidence: v.confidence,
    source_language: v.sourceLanguage,
    was_user_corrected: false,
  };
}

export function parseGeminiVehicleJson(raw: string): GeminiVehicleResponse {
  const parsed: unknown = JSON.parse(raw);
  return geminiVehicleResponseSchema.parse(parsed);
}

export const callableInputSchema = z.object({
  scanId: z.string().min(1).max(128),
  language: z.enum(["pl", "en"]),
});
