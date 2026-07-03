#!/bin/bash
# Builds the browser-playable HTML5 zip for itch.io upload.
#
# The game is single-file self-contained (see ../../CLAUDE.md), so the
# zip contains only index.html — no other files needed.
#
# Usage: ./build-html5.sh
# Output: desktop/dist/deadzone-v<VERSION>-html5.zip
#
# Upload it on itch.io as an HTML upload, tick "This file will be played
# in the browser", embed size 1200x680, enable "Click to launch in
# fullscreen" and "Enable scrollbars" = off.

set -euo pipefail
cd "$(dirname "$0")/.."   # cd into desktop/

# Prefer node when available (authoritative parser), but fall back to a
# shell regex so this script works even on a fresh machine before
# `npm install`. The HTML5 zip doesn't need Node at all — pure browser code.
if command -v node >/dev/null 2>&1; then
  VERSION=$(node -p "require('./package.json').version")
else
  VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' package.json | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
fi
GAME_HTML="../index.html"

if [ ! -f "$GAME_HTML" ]; then
  echo "Error: $GAME_HTML not found relative to $(pwd)" >&2
  exit 1
fi

mkdir -p dist
OUT="dist/deadzone-v${VERSION}-html5.zip"
rm -f "$OUT"

# -j: junk paths — put index.html at zip root, no ../ prefix
zip -j "$OUT" "$GAME_HTML"

SIZE=$(du -h "$OUT" | cut -f1)
echo ""
echo "✓ Built $OUT ($SIZE)"
echo ""
echo "Upload on itch.io:"
echo "  Kind of file       → HTML"
echo "  Play in browser    → check"
echo "  Embed viewport     → 1200 × 680"
echo "  Fullscreen button  → enable"
echo "  Mobile friendly    → your call (game auto-detects touch)"
