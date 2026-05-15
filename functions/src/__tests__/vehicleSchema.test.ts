import { describe, expect, it } from "vitest";

import {
  callableInputSchema,
  parseGeminiVehicleJson,
  toFirestoreVehicleInfo,
} from "../vehicleSchema";

describe("callableInputSchema", () => {
  it("parses valid payload", () => {
    const v = callableInputSchema.parse({
      scanId: "abc-123",
      language: "pl",
    });
    expect(v.scanId).toBe("abc-123");
    expect(v.language).toBe("pl");
  });

  it("rejects empty scanId", () => {
    expect(() =>
      callableInputSchema.parse({ scanId: "", language: "en" }),
    ).toThrow();
  });

  it("rejects missing scanId", () => {
    expect(() => callableInputSchema.parse({ language: "en" })).toThrow();
  });

  it("rejects invalid language", () => {
    expect(() =>
      callableInputSchema.parse({ scanId: "x", language: "de" }),
    ).toThrow();
  });
});

describe("vehicleSchema", () => {
  it("parses minimal valid Gemini JSON", () => {
    const raw = JSON.stringify({
      vehicleType: "car",
      brand: "VW",
      model: "Golf",
      generation: null,
      productionYears: "2012–2019",
      possibleEngines: ["1.4 TSI"],
      shortDescription: "Compact hatchback.",
      confidence: 0.72,
      sourceLanguage: "pl",
    });
    const v = parseGeminiVehicleJson(raw);
    const fs = toFirestoreVehicleInfo(v);
    expect(fs.vehicle_type).toBe("car");
    expect(fs.brand).toBe("VW");
    expect(fs.production_years).toBe("2012–2019");
    expect(fs.possible_engines).toEqual(["1.4 TSI"]);
  });

  it("rejects invalid vehicleType", () => {
    const raw = JSON.stringify({
      vehicleType: "spaceship",
      confidence: 0.5,
      sourceLanguage: "en",
    });
    expect(() => parseGeminiVehicleJson(raw)).toThrow();
  });
});
