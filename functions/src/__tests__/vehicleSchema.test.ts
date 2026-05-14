import { describe, expect, it } from "vitest";

import {
  parseGeminiVehicleJson,
  toFirestoreVehicleInfo,
} from "../vehicleSchema";

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
