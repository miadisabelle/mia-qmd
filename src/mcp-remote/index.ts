/**
 * CLI entry for `qmd mcp-remote` — Wave 1 stdio bridge.
 *
 * Refs miadisabelle/mia-qmd#10 (Wave 1, rispec 07).
 */

import { resolveConfig } from "./config.js";
import { startProxy } from "./proxy.js";

const HELP = `qmd mcp-remote — SSH-stdio MCP proxy to a remote QMD index

Usage:
  qmd mcp-remote [options]

Options (flag > env > default):
  --host <user@host>            SSH target          (env QMD_REMOTE_HOST)        [required]
  --remote-bin <path>           Path to remote qmd  (env QMD_REMOTE_BIN)         [default: qmd]
  --ssh-opts "<args>"           Extra ssh args      (env QMD_REMOTE_SSH_OPTS)
                                                    [default: -T -o BatchMode=yes -o ServerAliveInterval=30]
  --collections <a,b,c>         Default collections injected into query calls
                                                    (env QMD_REMOTE_COLLECTIONS)
  --no-collections              Disable injection   (env QMD_NO_COLLECTIONS=1)
  --log-level <error|warn|info|debug>
                                                    (env QMD_REMOTE_LOG_LEVEL)   [default: warn]
  -h, --help                    Show this help

Example:
  qmd mcp-remote --host mia@eury \\
    --remote-bin /home/mia/.nvm/versions/node/v22.22.2/bin/qmd \\
    --collections wikis-md,GUILLAUME-md,iaip-artefacts-md
`;

export async function main(argv: string[] = process.argv.slice(3)): Promise<void> {
  if (argv.includes("-h") || argv.includes("--help")) {
    process.stdout.write(HELP);
    return;
  }
  let config;
  try {
    config = resolveConfig(argv);
  } catch (err: any) {
    process.stderr.write(`${err?.message ?? err}\n`);
    process.exit(2);
  }
  try {
    await startProxy(config);
  } catch (err: any) {
    process.stderr.write(`qmd mcp-remote: failed to start proxy: ${err?.message ?? err}\n`);
    process.exit(1);
  }
}

// Run if invoked directly (bun src/mcp-remote/index.ts ...)
if (
  process.argv[1] &&
  (process.argv[1].endsWith("/mcp-remote/index.ts") ||
    process.argv[1].endsWith("/mcp-remote/index.js"))
) {
  main(process.argv.slice(2)).catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
