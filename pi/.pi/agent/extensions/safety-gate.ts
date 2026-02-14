import type { ExtensionAPI, ToolCallEvent } from "@mariozechner/pi-coding-agent";
import { readFileSync, appendFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { z } from "zod/v4";

// ---------------------------------------------------------------------------
// Schema & types
// ---------------------------------------------------------------------------

const permissionRuleSchema = z.object({
  tool: z.string(),
  matches: z
    .record(z.string(), z.union([z.string(), z.array(z.string())]))
    .optional(),
  action: z.enum(["allow", "ask", "reject"]),
});

const permissionsSchema = z.array(permissionRuleSchema);

type PermissionRule = z.infer<typeof permissionRuleSchema>;

type PermissionAction = PermissionRule["action"];

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

const EXTENSIONS_DIR = __dirname;
const AGENT_DIR = dirname(EXTENSIONS_DIR);
const PERMISSIONS_PATH = join(AGENT_DIR, "permissions.json");
const LOG_PATH = join(EXTENSIONS_DIR, "safety-gate.log");

// ---------------------------------------------------------------------------
// Fallback when permissions.json is missing or invalid
// ---------------------------------------------------------------------------

// Default action when no rule matches
const DEFAULT_ACTION: PermissionAction = "allow";

// Fallback rules when permissions.json fails to load — ask everything
const FAILURE_FALLBACK_PERMISSIONS: PermissionRule[] = [
  { tool: "*", action: "ask" },
];

// ---------------------------------------------------------------------------
// Load & validate permissions.json
// ---------------------------------------------------------------------------

type LoadResult =
  | { ok: true; permissions: PermissionRule[] }
  | { ok: false; error: string; permissions: PermissionRule[] };

const loadPermissions = (): LoadResult => {
  try {
    const raw = readFileSync(PERMISSIONS_PATH, "utf-8");
    const parsed = JSON.parse(raw) as unknown;
    const result = permissionsSchema.safeParse(parsed);

    if (!result.success) {
      return {
        ok: false,
        error: z.prettifyError(result.error),
        permissions: FAILURE_FALLBACK_PERMISSIONS,
      };
    }

    return { ok: true, permissions: result.data };
  } catch (e) {
    const message =
      e instanceof Error ? e.message : "Unknown error reading permissions.json";
    return { ok: false, error: message, permissions: FAILURE_FALLBACK_PERMISSIONS };
  }
};

// ---------------------------------------------------------------------------
// Logging
// ---------------------------------------------------------------------------

const log = (
  toolName: string,
  decision: PermissionAction,
  detail: string,
): void => {
  const timestamp = new Date().toISOString();
  const line = `[${timestamp}] ${decision.toUpperCase().padEnd(6)} ${toolName} — ${detail}\n`;
  try {
    appendFileSync(LOG_PATH, line);
  } catch {
    // Best-effort logging
  }
};

// ---------------------------------------------------------------------------
// Glob matching (supports * and ?, always case-insensitive)
// ---------------------------------------------------------------------------

const globToRegex = (pattern: string): RegExp => {
  const escaped = pattern.replace(/[.+^${}()|[\]\\]/g, "\\$&");
  const withWildcards = escaped.replace(/\*/g, ".*").replace(/\?/g, ".");
  return new RegExp(`^${withWildcards}$`, "is");
};

const globMatch = (value: string, pattern: string | string[]): boolean => {
  const patterns = Array.isArray(pattern) ? pattern : [pattern];
  return patterns.some((p) => globToRegex(p).test(value));
};

// ---------------------------------------------------------------------------
// Rule matching — first match wins
// ---------------------------------------------------------------------------

const getToolInput = (event: ToolCallEvent): Record<string, unknown> =>
  event.input as Record<string, unknown>;

const findMatchingRule = (
  permissions: PermissionRule[],
  event: ToolCallEvent,
): PermissionRule | undefined => {
  const input = getToolInput(event);

  for (const rule of permissions) {
    // 1. Check if tool name matches
    if (!globMatch(event.toolName, rule.tool)) continue;

    // 2. Check if all specific input conditions match
    if (rule.matches) {
      const matchEntries = Object.entries(rule.matches);
      const allMatches = matchEntries.every(([field, pattern]) => {
        const value = input[field];
        // If the tool input doesn't have this field, or it's not a string,
        // it cannot match a string glob pattern.
        if (typeof value !== "string") return false;
        return globMatch(value, pattern);
      });

      if (!allMatches) continue;
    }

    // If we got here, both tool name and all match conditions passed
    return rule;
  }
  return undefined;
};

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  let permissions: PermissionRule[] = [];
  const sessionAllowed = new Set<string>();

  const makeInputKey = (event: ToolCallEvent): string =>
    JSON.stringify(getToolInput(event));

  const reloadPermissions = (
    notify: (msg: string, level: "info" | "warning" | "error") => void,
  ) => {
    const result = loadPermissions();
    permissions = result.permissions;

    if (!result.ok) {
      log("system", "reject", `Failed to load permissions: ${result.error}`);
      notify(
        `⚠️ Failed to load permissions.json — falling back to ask-all\n${result.error}`,
        "error",
      );
    }
  };

  pi.on("session_start", async (_event, ctx) => {
    sessionAllowed.clear();
    reloadPermissions(ctx.ui.notify);
    log(
      "system",
      "allow",
      `Session started, loaded ${permissions.length} rules`,
    );
    ctx.ui.notify(
      `🛡️ Safety gate active (${permissions.length} rules)`,
      "info",
    );
  });

  pi.on("tool_call", async (event, ctx) => {
    const inputKey = makeInputKey(event);

    if (sessionAllowed.has(inputKey)) {
      log(event.toolName, "allow", `Session-allowed: ${inputKey}`);
      return;
    }

    const rule = findMatchingRule(permissions, event);
    const action = rule?.action ?? DEFAULT_ACTION;

    if (action === "allow") {
      log(event.toolName, "allow", "Rule matched: allow");
      return;
    }

    if (action === "reject") {
      log(event.toolName, "reject", `Rule matched: reject — ${inputKey}`);
      return { block: true, reason: "Rejected by permission rule" };
    }

    const details = Object.entries(getToolInput(event))
      .map(([k, v]) => `${k}: ${v}`)
      .join("\n");

    const choice = await ctx.ui.select(
      `⚠️ ${event.toolName} requires approval\n\n${details}`,
      ["Allow once", "Allow for session", "Reject"],
    );

    if (choice === "Allow for session") {
      sessionAllowed.add(inputKey);
      log(event.toolName, "allow", `User allowed for session: ${inputKey}`);
      return;
    }

    if (choice === "Allow once") {
      log(event.toolName, "allow", `User allowed once: ${inputKey}`);
      return;
    }

    log(event.toolName, "reject", `User denied: ${inputKey}`);
    return { block: true, reason: `User denied ${event.toolName}` };
  });
}
