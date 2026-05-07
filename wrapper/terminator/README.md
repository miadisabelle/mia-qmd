# Terminator qmd:// Handler

Make `qmd://` URIs returned by `scripts/qmd_remote.sh` clickable and resolvable inside Terminator.

## Quick Start

```bash
cd /workspace/repos/miadisabelle/mia-qmd/wrapper/terminator
./setup.sh
```

The script will:
- Check Terminator is installed
- Show what will be installed
- Ask for confirmation
- Copy files to `~/.config/terminator/plugins/` and `~/bin/`
- Update `~/.config/terminator/config` to enable the plugin
- Validate everything

Then restart Terminator and try:

```bash
scripts/qmd_remote.sh "Whispering Library"
```

Ctrl-click any `qmd://` URI in the output → source artifact opens in your default markdown viewer.

## Files

| File | Purpose |
|------|---------|
| `setup.sh` | Interactive installer (idempotent) |
| `qmd-open` | Wrapper script: SSH to eury, `bun src/cli/qmd.ts get`, cache locally, return path |
| `qmd_url_handler.py` | Terminator plugin: registers `qmd://` regex, calls wrapper on click |
| `config` | Example `~/.config/terminator/config` snippet |
| `qmd-handler/` | RISE specifications (Option A + B) and implementation notes |

## How It Works

1. **Plugin registration**: `qmd_url_handler.py` subclasses `terminatorlib.plugin.URLHandler` and registers regex `qmd://[A-Za-z0-9._/-]+`.
2. **User clicks**: Ctrl-click on matched text → plugin's `callback()` is called.
3. **Fetch**: Callback invokes `~/bin/qmd-open <uri>` which:
   - Checks `/tmp/qmd-cache/<hash>.md` (300s TTL)
   - On miss, SSH to `mia@eury`, run `bun src/cli/qmd.ts get <uri>`, cache result
   - Returns the local path
4. **Open**: Callback returns `file:///tmp/qmd-cache/<hash>.md`, Terminator opens via system handler (your default markdown viewer).

## Specifications

- **Option A** (implemented): Terminator plugin — local surface only.
- **Option B** (reference): System-wide XDG scheme handler — extends to all GTK apps.

See `qmd-handler/README.md` for full specs and rationale.

## Troubleshooting

**URI not underlined?**
- Terminator needs to restart for plugin to load.
- Check `~/.config/terminator/config`: `enabled_plugins` should list `QmdURLHandler`.

**Click doesn't open anything?**
- Check `/tmp/qmd-cache/error.log` for SSH/fetch errors.
- Verify SSH key is set up: `ssh mia@eury echo OK`
- Check `~/bin/qmd-open` is executable: `ls -l ~/bin/qmd-open`

**Slow first click?**
- First fetch includes SSH round-trip (~2–5s). Repeat clicks within 300s are instant (cached).
- Adjust `CACHE_TTL` in `qmd-open` if desired.

## Environment

The wrapper respects the same env vars as `scripts/qmd_remote.sh`:

```bash
REMOTE_HOST=mia@eury
REMOTE_WORKSPACE=/home/mia/workspace
REMOTE_QMD_REPO=$REMOTE_WORKSPACE/repos/miadisabelle/mia-qmd
REMOTE_BUN=/home/mia/.bun/bin/bun
QMD_CACHE_DIR=/tmp/qmd-cache
QMD_CACHE_TTL=300
```

Override as needed:

```bash
CACHE_TTL=600 REMOTE_HOST=other@host scripts/qmd_remote.sh "query"
```

## Related Issues

- miadisabelle/workspace#37 — Option A (Terminator plugin)
- miadisabelle/workspace#38 — Option B (system-wide handler)
