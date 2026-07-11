#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/VoidXTodoMac.xcodeproj"
APP_NAME="VoidXTodoMac.app"
INSTALL_PATH="/Applications/$APP_NAME"

cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/version.sh"

CURRENT_VERSION="$(current_app_version)"
if [[ "${VOIDX_SKIP_VERSION_BUMP:-0}" != "1" ]]; then
  APP_VERSION="$(next_app_version "$CURRENT_VERSION")"
else
  APP_VERSION="$CURRENT_VERSION"
fi

APP_BUILD="$(app_build_number "$APP_VERSION")"

xcodegen generate

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$ROOT_DIR/Generated/VoidXTodoMac-Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $APP_BUILD" "$ROOT_DIR/Generated/VoidXTodoMac-Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$ROOT_DIR/Generated/VoidXTodoWidget-Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $APP_BUILD" "$ROOT_DIR/Generated/VoidXTodoWidget-Info.plist"

XCODEBUILD_ARGS=(
  -project "$PROJECT"
  -scheme VoidXTodoMac
  -configuration Debug
  -quiet
  build
)

if [[ "${VOIDX_USE_DEVELOPMENT_PROFILES:-0}" == "1" ]]; then
  echo "⚙️  Building with Apple Developer signing profiles..."
  if [[ "${VOIDX_ALLOW_PROVISIONING_UPDATES:-0}" == "1" ]]; then
    XCODEBUILD_ARGS=("-allowProvisioningUpdates" "${XCODEBUILD_ARGS[@]}")
  fi
else
  echo "⚙️  Building with local ad-hoc signing..."
  XCODEBUILD_ARGS+=(
    "CODE_SIGN_STYLE=Manual"
    "CODE_SIGN_IDENTITY=-"
    "CODE_SIGNING_REQUIRED=YES"
    "CODE_SIGNING_ALLOWED=YES"
    "CODE_SIGN_ENTITLEMENTS="
    "DEVELOPMENT_TEAM="
  )
fi

xcodebuild "${XCODEBUILD_ARGS[@]}"

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

if [[ "${VOIDX_SKIP_VERSION_BUMP:-0}" != "1" ]]; then
  set_app_version "$APP_VERSION"
fi

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f \
  -R \
  -trusted \
  "$INSTALL_PATH"

pluginkit -a "$INSTALL_PATH/Contents/PlugIns/VoidXTodoWidget.appex" 2>/dev/null || true
open "$INSTALL_PATH"

echo "Installed and opened $INSTALL_PATH"
echo "Add the widget from the macOS widget gallery by searching for: VoidX Today"
