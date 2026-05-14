import * as admin from "firebase-admin";
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
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;

    let input: z.infer<typeof callableInputSchema>;
    try {
      input = callableInputSchema.parse(request.data ?? {});
    } catch {
      throw new HttpsError("invalid-argument", "Invalid scanId or language.");
    }

    const { scanId, language } = input;
    const ref = admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("scans")
      .doc(scanId);

    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Scan not found.");
    }

    const data = snap.data() ?? {};
    const remoteUrl = data["remote_image_url"] as string | undefined;
    if (!remoteUrl || typeof remoteUrl !== "string") {
      throw new HttpsError(
        "failed-precondition",
        "Scan has no remote_image_url. Sync the scan first.",
      );
    }

    const storagePath = `users/${uid}/scans/${scanId}/original.jpg`;
    const bucket = admin.storage().bucket();
    const file = bucket.file(storagePath);
    const [exists] = await file.exists();
    if (!exists) {
      throw new HttpsError(
        "failed-precondition",
        "Image not found in Storage. Sync the scan first.",
      );
    }

    const [buffer] = await file.download();
    if (!buffer.length) {
      throw new HttpsError("internal", "Empty image file.");
    }

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Server configuration error (missing Gemini key).",
      );
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-2.0-flash",
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
      const result = await model.generateContent([
        { text: buildPrompt(language) },
        imagePart,
      ]);
      const text = result.response.text();
      rawJson = extractJsonText(text);
    } catch (e) {
      const msg =
        e instanceof Error ? e.message.slice(0, 200) : "Gemini request failed.";
      await ref.set(
        {
          status: "failed",
          recognition_error: msg,
          recognized_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return {
        status: "failed",
        vehicle_info: null,
        recognition_error: msg,
      };
    }

    try {
      const vehicle = parseGeminiVehicleJson(rawJson);
      const vehicleInfo = toFirestoreVehicleInfo(vehicle);
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
      return {
        status: "recognized",
        vehicle_info: vehicleInfo,
        recognition_error: null,
      };
    } catch (e) {
      const msg =
        e instanceof Error
          ? `AI parse error: ${e.message}`.slice(0, 240)
          : "AI parse error.";
      await ref.set(
        {
          status: "failed",
          recognition_error: msg,
          recognized_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return {
        status: "failed",
        vehicle_info: null,
        recognition_error: msg,
      };
    }
  },
);
