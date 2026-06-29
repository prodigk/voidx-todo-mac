#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/VoidXTodoMac.xcodeproj"
APP_NAME="VoidXTodoMac.app"
INSTALL_PATH="/Applications/$APP_NAME"

cd "$ROOT_DIR"

xcodegen generate
xcodebuild \
  -project "$PROJECT" \
  -scheme VoidXTodoMac \
  -configuration Debug \
  -quiet \
  build

BUILT_APP="$(find "$HOME/Library/Developer/Xcode/DerivedData" \
  -path "*/Build/Products/Debug/$APP_NAME" \
  -type d \
  -print \
  | sort \
  | tail -1)"

if [[ -z "$BUILT_APP" || ! -d "$BUILT_APP" ]]; then
  echo "Could not find built app." >&2
  exit 1
fi

pkill -f "$INSTALL_PATH/Contents/MacOS/VoidXTodoMac" 2>/dev/null || true
rm -rf "$INSTALL_PATH"
cp -R "$BUILT_APP" "$INSTALL_PATH"

codesign --verify --deep --strict --verbose=2 "$INSTALL_PATH"

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f \
  -R \
  -trusted \
  "$INSTALL_PATH"

pluginkit -a "$INSTALL_PATH/Contents/PlugIns/VoidXTodoWidget.appex" 2>/dev/null || true
open "$INSTALL_PATH"

echo "Installed and opened $INSTALL_PATH"
echo "Add the widget from the macOS widget gallery by searching for: VoidX Today"
