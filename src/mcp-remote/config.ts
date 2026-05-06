/**
 * Resolves qmd-remote configuration from CLI flags and environment.
 *
 * Precedence (highest first): flag > env > default.
 * Required: QMD_REMOTE_HOST (--host).
 *
 * Refs miadisabelle/mia-qmd#10 (Wave 1, rispec 07).
 */

export type LogLevel = "error" | "warn" | "info" | "debug";

export type ResolvedConfig = {
  /** SSH target, e.g. "mia@eury" or "eury". */
  host: string;
  /** Path to the remote qmd binary, or "qmd" to rely on remote $PATH. */
  remoteBin: string;
  /** Extra args spliced into the `ssh` argv before the host. */
  sshOpts: string[];
  /** Default collection list injected into `query` calls; null = no injection. */
  collections: string[] | null;
  /** Proxy stderr verbosity. */
  logLevel: LogLevel;
};

const DEFAULT_SSH_OPTS = "-T -o BatchMode=yes -o ServerAliveInterval=30";
const DEFAULT_REMOTE_BIN = "qmd";
const DEFAULT_LOG_LEVEL: LogLevel = "warn";
const VALID_LOG_LEVELS: LogLevel[] = ["error", "warn", "info", "debug"];

/** Strip a `--flag=value` or `--flag value` pair from argv and return its value. */
function pickFlag(argv: string[], name: string): string | undefined {
  const eqPrefix = `--${name}=`;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === `--${name}`) return argv[i + 1];
    if (a !== undefined && a.startsWith(eqPrefix)) return a.slice(eqPrefix.length);
  }
  return undefined;
}

/** Detect a boolean flag (`--no-collections` style). */
function hasFlag(argv: string[], name: string): boolean {
  return argv.includes(`--${name}`);
}

function splitCollections(csv: string): string[] {
  return csv.split(",").map(s => s.trim()).filter(s => s.length > 0);
}

export function resolveConfig(argv: string[], env: NodeJS.ProcessEnv = process.env): ResolvedConfig {
  // --- host (required) -----------------------------------------------------
  const host = pickFlag(argv, "host") ?? env.QMD_REMOTE_HOST;
  if (!host) {
    throw new Error(
      "qmd mcp-remote: missing required --host (or QMD_REMOTE_HOST). " +
      "Example: qmd mcp-remote --host mia@eury",
    );
  }

  // --- remote binary -------------------------------------------------------
  const remoteBin = pickFlag(argv, "remote-bin") ?? env.QMD_REMOTE_BIN ?? DEFAULT_REMOTE_BIN;

  // --- ssh opts ------------------------------------------------------------
  const sshOptsRaw = pickFlag(argv, "ssh-opts") ?? env.QMD_REMOTE_SSH_OPTS ?? DEFAULT_SSH_OPTS;
  const sshOpts = sshOptsRaw.split(/\s+/).filter(s => s.length > 0);

  // --- collections (null = no injection) -----------------------------------
  let collections: string[] | null = null;
  const noColFlag = hasFlag(argv, "no-collections");
  const noColEnv = env.QMD_NO_COLLECTIONS === "1";
  if (!noColFlag && !noColEnv) {
    const colRaw = pickFlag(argv, "collections") ?? env.QMD_REMOTE_COLLECTIONS;
    if (colRaw !== undefined) {
      const list = splitCollections(colRaw);
      collections = list.length > 0 ? list : null;
    }
  }

  // --- log level -----------------------------------------------------------
  const logRaw = pickFlag(argv, "log-level") ?? env.QMD_REMOTE_LOG_LEVEL ?? DEFAULT_LOG_LEVEL;
  const logLevel: LogLevel = (VALID_LOG_LEVELS as string[]).includes(logRaw)
    ? (logRaw as LogLevel)
    : DEFAULT_LOG_LEVEL;

  return { host, remoteBin, sshOpts, collections, logLevel };
}
