"""qmd_url_handler.py — Terminator URL handler for qmd:// URIs.

Spec: ~/workspace/rispecs/qmd-handler/option-a-terminator-plugin.rispec.md
Issue: miadisabelle/workspace#37

Matches qmd://<collection>/<path> in terminal output, makes it Ctrl-clickable,
and resolves the click via ~/bin/qmd-open which fetches the source artifact
through the existing remote pipeline and writes a local cache file. The
callback returns file:///tmp/qmd-cache/<hash>.md for Terminator to open via
the system handler. On wrapper failure, returns the original qmd:// URI so
the user sees a default-handler error rather than silent loss.
"""

import os
import subprocess

import terminatorlib.plugin as plugin

AVAILABLE = ['QmdURLHandler']

QMD_OPEN = os.path.expanduser('~/bin/qmd-open')


class QmdURLHandler(plugin.URLHandler):
    capabilities = ['url_handler']
    handler_name = 'qmd_uri'
    match = r'\bqmd://[A-Za-z0-9._/\-]+'
    nameopen = 'Open QMD source'
    namecopy = 'Copy qmd:// URI'

    def callback(self, url):
        try:
            result = subprocess.run(
                [QMD_OPEN, url],
                capture_output=True,
                text=True,
                timeout=15,
            )
        except (OSError, subprocess.TimeoutExpired):
            return url
        if result.returncode != 0:
            return url
        path = result.stdout.strip()
        if not path or not os.path.isfile(path):
            return url
        return 'file://' + path
