#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_PNG="${1:-$ROOT_DIR/Assets/AppIcon-1024.png}"
ICONSET="$ROOT_DIR/.build/AppIcon.iconset"
OUTPUT_ICNS="$ROOT_DIR/Assets/AppIcon.icns"

if [[ ! -f "$SOURCE_PNG" ]]; then
  echo "Missing source icon: $SOURCE_PNG" >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/Assets" "$ROOT_DIR/.build"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

make_icon() {
  local size="$1"
  local filename="$2"
  /usr/bin/sips -s format png -z "$size" "$size" "$SOURCE_PNG" --out "$ICONSET/$filename" >/dev/null
}

make_icon 16 "icon_16x16.png"
make_icon 32 "icon_16x16@2x.png"
make_icon 32 "icon_32x32.png"
make_icon 64 "icon_32x32@2x.png"
make_icon 128 "icon_128x128.png"
make_icon 256 "icon_128x128@2x.png"
make_icon 256 "icon_256x256.png"
make_icon 512 "icon_256x256@2x.png"
make_icon 512 "icon_512x512.png"
make_icon 1024 "icon_512x512@2x.png"

/usr/bin/iconutil -c icns "$ICONSET" -o "$OUTPUT_ICNS"

echo "Generated $OUTPUT_ICNS"
