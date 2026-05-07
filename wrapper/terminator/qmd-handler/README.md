# qmd:// Handler — RISE Specifications

> Make `qmd://` URIs returned by `scripts/qmd_remote.sh` directly actionable from the terminal so the source artifact appears in seconds.

**Framework**: RISE v1.2
**Date**: 2026-05-01

---

## Context

`scripts/qmd_remote.sh "<query>"` returns hits like:

```
qmd://iaip-artefacts-md/sources/2509-26514v1.md
```

Today these are inert text. The reader copies the URI, re-runs `qmd get` over SSH, pipes to a temp file, opens it. Each lookup is a small ritual of friction.

## Two Specifications

| File | Option | Scope |
|---|---|---|
| [option-a-terminator-plugin.rispec.md](./option-a-terminator-plugin.rispec.md) | A | Terminator-only: URL plugin + fetch wrapper |
| [option-b-xdg-scheme-handler.rispec.md](./option-b-xdg-scheme-handler.rispec.md) | B | System-wide: `x-scheme-handler/qmd` via `.desktop` |

A is self-contained and gives the visual cue (underline + Ctrl-click) directly inside Terminator. B reaches every GTK app but still needs A for Terminator to recognize the scheme as clickable.

## Relationship

Option A and Option B compose. A registers the *clickable surface*; B registers the *system-wide route*. Implementing A first delivers the desired outcome inside the primary surface (Mia's terminal). B can layer on later if the same clickability is desired in chat clients, editors, or note-taking GTK apps.

## Source Reference

- `scripts/qmd_remote.sh` — remote query script that emits `qmd://` URIs
- Terminator plugin API: `/usr/lib/python3/dist-packages/terminatorlib/plugin.py` (class `URLHandler`)
- Built-in URL plugin examples: `/usr/lib/python3/dist-packages/terminatorlib/plugins/url_handlers.py`
