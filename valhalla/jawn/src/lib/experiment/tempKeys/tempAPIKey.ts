import generateApiKey from "generate-api-key";
import { hashAuth } from "../../../utils/hash";
import { supabaseServer } from "../../db/supabase";
import { Result, err, ok } from "../../shared/result";
import { BaseTempKey } from "./baseTempKey";
import { cacheResultCustom } from "../../../utils/cacheResult";
import { KVCache } from "../../cache/kvCache";
import { KeyManager } from "../../../managers/apiKeys/KeyManager";

const CACHE_TTL = 60 * 1000 * 30; // 30 minutes

const kvCache = new KVCache(CACHE_TTL);

const IS_EU = process.env.AWS_REGION === "eu-west-1";

async function getHeliconeApiKey() {
  const apiKey = `sk-helicone${IS_EU ? "-eu" : ""}-${generateApiKey({
    method: "base32",
    dashes: true,
  }).toString()}`.toLowerCase();
  return apiKey;
}

class TempHeliconeAPIKey implements BaseTempKey {
  private keyUsed = false;
  constructor(private apiKey: string, private heliconeApiKeyId: string) {}

  async cleanup() {
    if (this.keyUsed) {
      return;
    }

    await supabaseServer.client
      .from("helicone_api_keys")
      .update({
        soft_delete: true,
      })
      .eq("temp_key", true)
      .lt("created_at", new Date(Date.now() - CACHE_TTL).toISOString());

    return await supabaseServer.client
      .from("helicone_api_keys")
      .delete({
        count: "exact",
      })
      .eq("id", this.heliconeApiKeyId);
  }

  async with<T>(callback: (apiKey: string) => Promise<T>): Promise<T> {
    if (this.keyUsed) {
      throw new Error("Key already used");
    }

    this.keyUsed = true;
    return callback(this.apiKey)
      .then(async (t) => {
        await this.cleanup();
        return t;
      })
      .finally(async () => {
        await this.cleanup();
      });
  }
}

export async function generateHeliconeAPIKey(
  organizationId: string,
  keyName?: string,
  keyPermissions?: "rw" | "r" | "w"
): Promise<
  Result<
    {
      apiKey: string;
      heliconeApiKeyId: string;
    },
    string
  >
> {
  try {
    // Create a KeyManager with the necessary auth params
    const keyManager = new KeyManager({
      userId: "", // This will be replaced by the org owner
      organizationId: organizationId,
    });

    // Use the KeyManager to create a temporary key
    const result = await keyManager.createTempKey(
      keyName ?? "auto-generated-experiment-key",
      keyPermissions ?? "w"
    );

    if (result.error || !result.data) {
      return err(result.error || "Failed to create API key");
    }

    return ok({
      apiKey: result.data.apiKey,
      heliconeApiKeyId: result.data.id,
    });
  } catch (error) {
    return err(`Failed to generate Helicone API Key: ${error}`);
  }
}

export async function generateTempHeliconeAPIKey(
  organizationId: string,
  keyName?: string
): Promise<Result<TempHeliconeAPIKey, string>> {
  const apiKey = await cacheResultCustom(
    "generateTempHeliconeAPIKey-" + organizationId + (keyName ?? ""),
    async () => await generateHeliconeAPIKey(organizationId, keyName),
    kvCache
  );

  if (apiKey.error) {
    return err(apiKey.error);
  } else {
    return ok(
      new TempHeliconeAPIKey(apiKey.data!.apiKey, apiKey.data!.heliconeApiKeyId)
    );
  }
}
