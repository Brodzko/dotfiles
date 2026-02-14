import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

const DANGEROUS_PATTERNS = [
  { pattern: /\brm\s+-rf\b/, label: "rm -rf" },
  { pattern: /\bDROP\s+TABLE\b/i, label: "DROP TABLE" },
  { pattern: /\bsudo\b/, label: "sudo" },
  { pattern: /\bformat\b/, label: "format" },
  { pattern: /\bnpx\b/, label: "npx" },
  { pattern: /\bcurl\b/, label: "curl" },
];

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("🛡️ Safety gate active", "info");
  });

  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("bash", event)) return;

    const command = event.input.command;
    const matches = DANGEROUS_PATTERNS.filter((p) => p.pattern.test(command));

    if (matches.length === 0) return;

    const labels = matches.map((m) => m.label).join(", ");
    const ok = await ctx.ui.confirm(
      `⚠️ Dangerous command detected: ${labels}`,
      `Allow execution?\n\n$ ${command}`,
    );

    if (!ok) {
      return { block: true, reason: `User blocked dangerous command (${labels})` };
    }
  });
}
