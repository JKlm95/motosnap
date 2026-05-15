import * as admin from "firebase-admin";
import type { DocumentSnapshot } from "firebase-admin/firestore";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { z } from "zod";

import {
  callableInputSchema,
  parseGeminiVehicleJson,
  toFirestoreVehicleInfo,
} from "./vehicleSchema.js";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Callable contract (must match Flutter `FirebaseVehicleAnalysisService.analyzeScan`):
 * - `request.data.scanId`: string, non-empty (UUID skanu)
 * - `request.data.language`: `"pl"` | `"en"`
 * Flutter sends: `httpsCallable('analyzeVehicleScan').call({ scanId, language })`.
 */
const STAGE = {
  started: "started",
  auth: "auth_ok",
  inputParsed: "input_parsed",
  firestoreRead: "firestore_read_scan",
  storagePath: "storage_path_resolved",
  storageDownload: "storage_download",
  gemini: "gemini",
  geminiParse: "gemini_parse_json",
  zodValidate: "zod_validate",
  firestoreWriteSuccess: "firestore_write_recognized",
  firestoreWriteFailed: "firestore_write_failed",
  success: "function_success",
} as const;

function logInfo(
  message: string,
  fields: Record<string, string | boolean | number | null | undefined>,
): void {
  console.info(
    JSON.stringify({
      severity: "INFO",
      fn: "analyzeVehicleScan",
      message,
      ...fields,
    }),
  );
}

function logError(
  stage: string,
  err: unknown,
  ctx: { uid?: string; scanId?: string },
): void {
  const name = err instanceof Error ? err.name : typeof err;
  const message = err instanceof Error ? err.message : String(err);
  const stack = err instanceof Error ? err.stack : undefined;
  console.error(
    JSON.stringify({
      severity: "ERROR",
      fn: "analyzeVehicleScan",
      stage,
      uid: ctx.uid ?? null,
      scanId: ctx.scanId ?? null,
      errorName: name,
      errorMessage: message,
      stack: stack ?? null,
    }),
  );
}

function buildPrompt(language: "pl" | "en"): string {
  const lang = language === "pl" ? "Polish" : "English";
  return [
    `You are a vehicle identification assistant. Respond in JSON only (no markdown, no code fences).`,
    `All human-readable string fields (brand, model, generation, productionYears, possibleEngines items, shortDescription) should be written in ${lang} where applicable.`,
    `sourceLanguage must be exactly "${language}".`,
    `Identify the main vehicle in the image.`,
    `If unsure, still return your best estimate but lower confidence (0..1).`,
    `Do not invent exact year, VIN, owner, license plate, or any private data.`,
    `Do not describe people or license plates.`,
    `For productionYears use a plausible model/generation production range text if reasonably known, otherwise null.`,
    `possibleEngines: at most 4 short strings; only if reasonably known; otherwise [].`,
    `shortDescription: at most 2 sentences; null if nothing useful.`,
    `vehicleType must be one of: car, motorcycle, truck, bus, aircraft, boat, train, agricultural, construction, military, emergency, bicycle, scooter, other, unknown.`,
    `JSON schema keys exactly: vehicleType, brand, model, generation, productionYears, possibleEngines, shortDescription, confidence, sourceLanguage.`,
  ].join("\n");
}

function extractJsonText(text: string): string {
  let t = text.trim();
  if (t.startsWith("```")) {
    t = t.replace(/^```[a-zA-Z]*\n?/, "").replace(/\n?```\s*$/u, "");
  }
  return t.trim();
}

export const analyzeVehicleScan = onCall(
  {
    region: "us-central1",
    secrets: [geminiApiKey],
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async (request) => {
    logInfo(STAGE.started, { hasAuth: Boolean(request.auth?.uid) });

    if (!request.auth?.uid) {
      logError("unauthenticated", new Error("Missing auth context"), {});
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    logInfo(STAGE.auth, { uid });

    const rawKeys =
      request.data != null && typeof request.data === "object"
        ? Object.keys(request.data as object).join(",")
        : "";
    logInfo("request_data_shape", {
      uid,
      dataKeys: rawKeys || "(empty)",
    });

    let input: z.infer<typeof callableInputSchema>;
    try {
      input = callableInputSchema.parse(request.data ?? {});
    } catch (e) {
      logError("invalid_argument_parse", e, { uid });
      throw new HttpsError("invalid-argument", "Invalid scanId or language.");
    }

    const { scanId, language } = input;
    logInfo(STAGE.inputParsed, { uid, scanId, language });

    const ref = admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("scans")
      .doc(scanId);

    const scanDocPath = ref.path;
    logInfo("firestore_scan_path", { uid, scanId, path: scanDocPath });

    let snap: DocumentSnapshot;
    try {
      snap = await ref.get();
    } catch (e) {
      logError(STAGE.firestoreRead, e, { uid, scanId });
      throw new HttpsError("internal", "Could not read scan.");
    }

    if (!snap.exists) {
      logInfo("firestore_scan_missing", { uid, scanId, exists: false });
      throw new HttpsError("not-found", "Scan not found.");
    }
    logInfo("firestore_scan_present", { uid, scanId, exists: true });

    const docData = snap.data() ?? {};
    const remoteUrl = docData["remote_image_url"] as string | undefined;
    if (!remoteUrl || typeof remoteUrl !== "string") {
      logInfo("remote_image_url_missing", { uid, scanId });
      throw new HttpsError(
        "failed-precondition",
        "Scan has no remote image. Sync the scan first.",
      );
    }

    /** Must match Flutter upload: `users/{uid}/scans/{scanId}/original.jpg` */
    const storagePath = `users/${uid}/scans/${scanId}/original.jpg`;
    logInfo(STAGE.storagePath, { uid, scanId, storagePath });

    const bucket = admin.storage().bucket();
    const file = bucket.file(storagePath);

    let exists = false;
    try {
      [exists] = await file.exists();
    } catch (e) {
      logError("storage_exists_check", e, { uid, scanId });
      throw new HttpsError("internal", "Could not verify image in storage.");
    }

    if (!exists) {
      logInfo("storage_image_missing", { uid, scanId, storagePath });
      throw new HttpsError("not-found", "Scan image not found in storage.");
    }

    let buffer: Buffer;
    try {
      logInfo("image_download_started", { uid, scanId });
      [buffer] = await file.download();
      logInfo("image_download_finished", {
        uid,
        scanId,
        byteLength: buffer.length,
      });
    } catch (e) {
      logError(STAGE.storageDownload, e, { uid, scanId });
      throw new HttpsError("internal", "Could not download scan image.");
    }

    if (!buffer.length) {
      logError("empty_image_buffer", new Error("zero bytes"), { uid, scanId });
      throw new HttpsError("internal", "Empty image file.");
    }

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      logError("gemini_key_missing", new Error("GEMINI_API_KEY empty"), {
        uid,
        scanId,
      });
      throw new HttpsError(
        "failed-precondition",
        "Server configuration error.",
      );
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      generationConfig: {
        responseMimeType: "application/json",
      },
    });

    const imagePart = {
      inlineData: {
        mimeType: "image/jpeg",
        data: buffer.toString("base64"),
      },
    };

    let rawJson: string;
    try {
      logInfo("gemini_request_started", { uid, scanId, model: "gemini-2.5-flash" });
      const result = await model.generateContent([
        { text: buildPrompt(language) },
        imagePart,
      ]);
      const text = result.response.text();
      rawJson = extractJsonText(text);
      logInfo("gemini_response_received", {
        uid,
        scanId,
        jsonCharLength: rawJson.length,
      });
    } catch (e) {
      logError(STAGE.gemini, e, { uid, scanId });
      const msg =
        e instanceof Error ? e.message.slice(0, 200) : "Gemini request failed.";
      try {
        logInfo("firestore_update_failed_status_started", { uid, scanId });
        await ref.set(
          {
            status: "failed",
            recognition_error: msg,
            recognized_at: admin.firestore.FieldValue.serverTimestamp(),
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        logInfo("firestore_update_failed_status_finished", { uid, scanId });
      } catch (writeErr) {
        logError(STAGE.firestoreWriteFailed, writeErr, { uid, scanId });
        throw new HttpsError("internal", "Recognition failed.");
      }
      /**
       * Structured 200 response (not HttpsError) so Flutter can merge `failed` into Hive
       * via `FirebaseVehicleAnalysisService._applyResponseAndReturn`.
       */
      logInfo(STAGE.success, { uid, scanId, outcome: "failed_gemini" });
      return {
        status: "failed",
        vehicle_info: null,
        recognition_error: msg,
        recognized_at: new Date().toISOString(),
      };
    }

    let parsedVehicle: ReturnType<typeof parseGeminiVehicleJson>;
    try {
      logInfo(STAGE.geminiParse, { uid, scanId });
      logInfo(STAGE.zodValidate, { uid, scanId });
      parsedVehicle = parseGeminiVehicleJson(rawJson);
      logInfo("zod_validation_passed", { uid, scanId });
    } catch (e) {
      logError(STAGE.zodValidate, e, { uid, scanId });
      const msg =
        e instanceof Error
          ? `AI parse error: ${e.message}`.slice(0, 240)
          : "AI parse error.";
      try {
        logInfo("firestore_update_failed_status_started", { uid, scanId });
        await ref.set(
          {
            status: "failed",
            recognition_error: msg,
            recognized_at: admin.firestore.FieldValue.serverTimestamp(),
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        logInfo("firestore_update_failed_status_finished", { uid, scanId });
      } catch (writeErr) {
        logError(STAGE.firestoreWriteFailed, writeErr, { uid, scanId });
        throw new HttpsError("internal", "Recognition failed.");
      }
      logInfo(STAGE.success, { uid, scanId, outcome: "failed_zod" });
      return {
        status: "failed",
        vehicle_info: null,
        recognition_error: msg,
        recognized_at: new Date().toISOString(),
      };
    }

    const vehicleInfo = toFirestoreVehicleInfo(parsedVehicle);
    try {
      logInfo("firestore_update_recognized_started", { uid, scanId });
      await ref.set(
        {
          status: "recognized",
          vehicle_info: vehicleInfo,
          recognition_error: null,
          recognized_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      logInfo("firestore_update_recognized_finished", { uid, scanId });
    } catch (e) {
      logError(STAGE.firestoreWriteSuccess, e, { uid, scanId });
      throw new HttpsError("internal", "Could not save recognition result.");
    }

    logInfo(STAGE.success, { uid, scanId, outcome: "recognized" });
    return {
      status: "recognized",
      vehicle_info: vehicleInfo,
      recognition_error: null,
      recognized_at: new Date().toISOString(),
    };
  },
);
