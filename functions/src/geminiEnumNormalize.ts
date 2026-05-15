/** Wartości `vehicleType` zgodne ze schematem Zod (angielskie tokeny). */
export const VEHICLE_TYPE_ENGLISH = [
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
] as const;

export type VehicleTypeEnglish = (typeof VEHICLE_TYPE_ENGLISH)[number];

const VEHICLE_TYPE_SET = new Set<string>(VEHICLE_TYPE_ENGLISH);

/**
 * Usuwa znaki diakrytyczne (NFD) dla dopasowania aliasów PL → EN.
 */
export function stripDiacritics(input: string): string {
  const nfd = input.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  return nfd.replace(/\u0142/gi, "l");
}

function canonicalKey(raw: string): string {
  return stripDiacritics(raw.trim().toLowerCase());
}

/**
 * Alias PL / wariant zapisu → token angielski ze schematu.
 * Klucze: ASCII, lower-case (po stripDiacritics + toLowerCase wejścia).
 */
const VEHICLE_TYPE_SYNONYMS: Record<string, VehicleTypeEnglish> = {
  motocykl: "motorcycle",
  moto: "motorcycle",
  samochod: "car",
  auto: "car",
  osobowy: "car",
  ciezarowka: "truck",
  tir: "truck",
  dostawczy: "truck",
  van: "truck",
  autobus: "bus",
  rower: "bicycle",
  skuter: "scooter",
  hulajnoga: "scooter",
  lodz: "boat",
  statek: "boat",
  pociag: "train",
  samolot: "aircraft",
  lotniczy: "aircraft",
  rolniczy: "agricultural",
  budowlany: "construction",
  wojskowy: "military",
  sluzbowy: "emergency",
  pogotowie: "emergency",
  karetka: "emergency",
  inny: "other",
  nieznany: "unknown",
  niewiadomy: "unknown",
};

/**
 * Zwraca angielski token `vehicleType` dla Zod, albo `undefined` gdy brak bezpiecznej normalizacji.
 */
export function normalizeVehicleTypeValue(raw: unknown): string | undefined {
  if (typeof raw !== "string") {
    return undefined;
  }
  const key = canonicalKey(raw);
  if (key.length === 0) {
    return undefined;
  }
  if (VEHICLE_TYPE_SET.has(key)) {
    return key;
  }
  return VEHICLE_TYPE_SYNONYMS[key];
}

export type EnumNormalizeResult = {
  normalized: Record<string, unknown>;
  vehicleTypeChanged: boolean;
  vehicleTypeFrom?: string;
  vehicleTypeTo?: string;
};

/**
 * Przed Zod: `vehicleType` → angielski token; trim, lower-case, usunięcie diakrytyków + mapa synonimów.
 * Pola `fuelType` / `drivetrain` — gdy trafią do schematu odpowiedzi, rozszerz tutaj normalizację.
 */
export function applyGeminiEnumNormalization(
  obj: Record<string, unknown>,
): EnumNormalizeResult {
  const normalized = { ...obj };
  const raw = normalized["vehicleType"];
  if (typeof raw !== "string") {
    return { normalized, vehicleTypeChanged: false };
  }
  const key = canonicalKey(raw);
  const resolved = VEHICLE_TYPE_SET.has(key)
    ? key
    : (VEHICLE_TYPE_SYNONYMS[key] ?? undefined);
  if (resolved === undefined) {
    return { normalized, vehicleTypeChanged: false };
  }
  if (resolved !== raw) {
    normalized["vehicleType"] = resolved;
    return {
      normalized,
      vehicleTypeChanged: true,
      vehicleTypeFrom: raw,
      vehicleTypeTo: resolved,
    };
  }
  normalized["vehicleType"] = resolved;
  return { normalized, vehicleTypeChanged: false };
}
