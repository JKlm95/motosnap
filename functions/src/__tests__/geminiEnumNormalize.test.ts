import { describe, expect, it } from "vitest";

import {
  applyGeminiEnumNormalization,
  normalizeVehicleTypeValue,
  stripDiacritics,
} from "../geminiEnumNormalize";

describe("stripDiacritics", () => {
  it("usuwa polskie znaki diakrytyczne", () => {
    expect(stripDiacritics("samochód")).toBe("samochod");
    expect(stripDiacritics("ciężarówka")).toBe("ciezarowka");
  });
});

describe("normalizeVehicleTypeValue", () => {
  it("mapuje motocykl → motorcycle", () => {
    expect(normalizeVehicleTypeValue("motocykl")).toBe("motorcycle");
  });

  it("mapuje z diakrytykami samochód → car", () => {
    expect(normalizeVehicleTypeValue("Samochód")).toBe("car");
  });

  it("mapuje ciezarowka bez polskich znaków → truck", () => {
    expect(normalizeVehicleTypeValue("ciezarowka")).toBe("truck");
  });

  it("poprawny token EN zostaje", () => {
    expect(normalizeVehicleTypeValue("motorcycle")).toBe("motorcycle");
  });

  it("normalizuje wielkość liter", () => {
    expect(normalizeVehicleTypeValue("Car")).toBe("car");
  });

  it("śmieci → undefined", () => {
    expect(normalizeVehicleTypeValue("spaceship")).toBeUndefined();
  });
});

describe("applyGeminiEnumNormalization", () => {
  it("nadpisuje vehicleType gdy alias PL", () => {
    const { normalized, vehicleTypeChanged } = applyGeminiEnumNormalization({
      vehicleType: "motocykl",
      confidence: 0.5,
      sourceLanguage: "pl",
    });
    expect(vehicleTypeChanged).toBe(true);
    expect(normalized.vehicleType).toBe("motorcycle");
  });

  it("nie zmienia już poprawnego EN", () => {
    const { normalized, vehicleTypeChanged } = applyGeminiEnumNormalization({
      vehicleType: "motorcycle",
      confidence: 0.5,
      sourceLanguage: "en",
    });
    expect(vehicleTypeChanged).toBe(false);
    expect(normalized.vehicleType).toBe("motorcycle");
  });
});
