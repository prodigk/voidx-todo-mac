#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="VoidXTodoMac"
WIDGET_NAME="VoidXTodoWidget"
APP_BUNDLE="$ROOT_DIR/dist/VoidX Todo.app"
EXECUTABLE="$ROOT_DIR/.build/debug/$APP_NAME"
WIDGET_EXECUTABLE="$ROOT_DIR/.build/debug/$WIDGET_NAME"
ICON_FILE="$ROOT_DIR/Assets/AppIcon.icns"
WIDGET_APPEX="$APP_BUNDLE/Contents/PlugIns/$WIDGET_NAME.appex"

cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/version.sh"

CURRENT_VERSION="$(current_app_version)"
if [[ "${VOIDX_SKIP_VERSION_BUMP:-0}" != "1" ]]; then
    APP_VERSION="$(next_app_version "$CURRENT_VERSION")"
else
    APP_VERSION="$CURRENT_VERSION"
fi

APP_BUILD="$(app_build_number "$APP_VERSION")"

swift build
scripts/make-app-icon.sh

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$WIDGET_APPEX/Contents/MacOS"
mkdir -p "$WIDGET_APPEX/Contents/Resources"

cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ICON_FILE" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
cp "$WIDGET_EXECUTABLE" "$WIDGET_APPEX/Contents/MacOS/$WIDGET_NAME"
chmod +x "$WIDGET_APPEX/Contents/MacOS/$WIDGET_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIdentifier</key>
    <string>com.voidx.todo.mac</string>
    <key>CFBundleName</key>
    <string>VoidX Todo</string>
    <key>CFBundleDisplayName</key>
    <string>VoidX Todo</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>VoidX Todo URL</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>voidxtodo</string>
            </array>
        </dict>
    </array>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
    <key>CFBundleVersion</key>
    <string>$APP_BUILD</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

cat > "$WIDGET_APPEX/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$WIDGET_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIdentifier</key>
    <string>com.voidx.todo.mac.widget</string>
    <key>CFBundleName</key>
    <string>VoidX Today Widget</string>
    <key>CFBundleDisplayName</key>
    <string>VoidX Today</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
    <key>CFBundleVersion</key>
    <string>$APP_BUILD</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
    <key>UIDeviceFamily</key>
    <array>
        <integer>2</integer>
    </array>
</dict>
</plist>
PLIST

codesign --force --sign - "$WIDGET_APPEX" >/dev/null
codesign --force --sign - "$APP_BUNDLE" >/dev/null

if [[ "${VOIDX_SKIP_VERSION_BUMP:-0}" != "1" ]]; then
    set_app_version "$APP_VERSION"
fi

open "$APP_BUNDLE"
