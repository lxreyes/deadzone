#!/bin/bash
# Pushes every already-built artifact to itch.io via the butler CLI.
#
# Prerequisites:
#   1. butler installed — https://itch.io/docs/butler/installing.html
#   2. Logged in once via `butler login` (stores an API key locally)
#   3. Your itch.io game page exists (create it at
#      https://itch.io/game/new, mark it "Uploads only", channels get
#      auto-created on first push)
#   4. Build artifacts exist in desktop/dist/ (run build-all.sh first)
#
# Usage:
#   ./upload-itch.sh                          # uses defaults below
#   ITCH_USER=lxreyes ITCH_GAME=deadzone ./upload-itch.sh
#
# Channels:
#   html5 → browser-playable
#   mac   → macOS .dmg / .zip
#   win   → Windows .exe
#   linux → Linux .AppImage / .tar.gz

set -euo pipefail
cd "$(dirname "$0")/.."   # cd into desktop/

ITCH_USER=${ITCH_USER:-lxreyes}
ITCH_GAME=${ITCH_GAME:-deadzone}
TARGET="${ITCH_USER}/${ITCH_GAME}"

command -v butler >/dev/null 2>&1 || {
  cat <<EOF >&2
Error: butler CLI not found on PATH.

Install it:
  macOS   → download from https://itch.io/docs/butler/installing.html
            (or 'brew install butler' via a homebrew tap if available)
  Linux   → download the binary, unzip, add to PATH
  Windows → download itch app which bundles butler, add to PATH

Then run once:
  butler login
EOF
  exit 1
}

if command -v node >/dev/null 2>&1; then
  VERSION=$(node -p "require('./package.json').version")
else
  VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' package.json | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
fi
PUSHED=0

push_if_exists() {
  local file="$1"
  local channel="$2"
  if [ -f "$file" ]; then
    echo "→ pushing $file to ${TARGET}:${channel}"
    butler push "$file" "${TARGET}:${channel}" --userversion "$VERSION"
    PUSHED=$((PUSHED + 1))
  fi
}

# HTML5
push_if_exists "dist/deadzone-v${VERSION}-html5.zip" "html5"

# macOS — prefer .dmg, fall back to .zip
for f in dist/*mac*.dmg; do push_if_exists "$f" "mac"; done
# only push zip if no dmg was found this run
if [ "$PUSHED" -eq 1 ] && ! ls dist/*mac*.dmg >/dev/null 2>&1; then
  for f in dist/*mac*.zip; do push_if_exists "$f" "mac"; done
fi

# Windows
for f in dist/*win*.exe; do push_if_exists "$f" "win"; done

# Linux — prefer AppImage, fall back to tar.gz
for f in dist/*linux*.AppImage; do push_if_exists "$f" "linux"; done

echo ""
if [ "$PUSHED" -gt 0 ]; then
  echo "✓ Pushed $PUSHED artifact(s) to $TARGET (version $VERSION)"
  echo "  See build status at: https://itch.io/dashboard"
else
  echo "⚠ No artifacts found in dist/ — run scripts/build-all.sh first"
  exit 1
fi
