#!/bin/bash
# Produces every shippable artifact for itch.io / Steam:
#   1. Browser-playable HTML5 zip
#   2. Native app for the current OS (mac | win | linux)
#
# Cross-platform builds (e.g. Windows .exe from macOS) require additional
# tooling; see electron-builder docs. For now this only produces builds for
# whichever OS you're running on — most flexible flow is to run this script
# on each target OS.
#
# Usage: ./build-all.sh

set -euo pipefail
cd "$(dirname "$0")/.."   # cd into desktop/

echo "═══ HTML5 browser bundle ═══"
bash scripts/build-html5.sh

echo ""
echo "═══ Native app for current platform ═══"
if [ ! -d "node_modules" ]; then
  echo "First-time setup — running npm install..."
  npm install
fi

# Detect current OS for the right build target label
case "$(uname -s)" in
  Darwin*)  echo "Detected macOS → building .dmg + .zip"; npm run build:mac ;;
  Linux*)   echo "Detected Linux → building .AppImage + .tar.gz"; npm run build:linux ;;
  MINGW*|MSYS*|CYGWIN*|Windows*)
            echo "Detected Windows → building NSIS + portable .exe"; npm run build:win ;;
  *)        echo "Unknown OS — running default build target"; npm run build ;;
esac

echo ""
echo "═══ Done ═══"
ls -lh dist/
