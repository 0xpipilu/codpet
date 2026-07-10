#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_ROOT="$(cd "$PROJECT_ROOT/../.." && pwd)"
APP_NAME="CodpetPersonal"
PRODUCT_NAME="CodpetPersonal"
DEVELOPER_DIR_CANDIDATE="/Applications/Xcode.app/Contents/Developer"
BUILD_DIR="$PROJECT_ROOT/.build"
CACHE_ROOT="$BUILD_DIR/local-cache"
MODULE_CACHE_DIR="$BUILD_DIR/ModuleCache.noindex"
SWIFTPM_CACHE_DIR="$CACHE_ROOT/swiftpm-cache"
SWIFTPM_CONFIG_DIR="$CACHE_ROOT/swiftpm-config"
SWIFTPM_SECURITY_DIR="$CACHE_ROOT/swiftpm-security"
DIST_APP_DIR="$PROJECT_ROOT/dist/$APP_NAME.app"
EXECUTABLE_PATH="$BUILD_DIR/debug/$PRODUCT_NAME"
APP_ICON_PNG="$PROJECT_ROOT/appicon.png"
APP_ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
APP_ICON_ICNS="$BUILD_DIR/AppIcon.icns"
FONT_SOURCE="$PROJECT_ROOT/sysfont.otf"
MENU_FONT_SOURCE="$WORKSPACE_ROOT/apps/_local-assets/fonts/ChiKareGo.ttf"
LABEL_FONT_SOURCE="$WORKSPACE_ROOT/apps/_local-assets/fonts/Habbo.ttf"
FONT_DIST_DIR="$DIST_APP_DIR/Contents/Resources/Fonts"
FONT_DIST_PATH="$FONT_DIST_DIR/sysfont.otf"
CATALOG_DIST_DIR="$DIST_APP_DIR/Contents/Resources/Catalog"
CATALOG_REF="origin/main"

RUN_AFTER_BUILD=1

for arg in "$@"; do
  case "$arg" in
    --build-only)
      RUN_AFTER_BUILD=0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      echo "Usage: $0 [--build-only]" >&2
      exit 2
      ;;
  esac
done

if [[ -d "$DEVELOPER_DIR_CANDIDATE" ]]; then
  export DEVELOPER_DIR="$DEVELOPER_DIR_CANDIDATE"
fi

mkdir -p \
  "$MODULE_CACHE_DIR" \
  "$SWIFTPM_CACHE_DIR" \
  "$SWIFTPM_CONFIG_DIR" \
  "$SWIFTPM_SECURITY_DIR" \
  "$PROJECT_ROOT/dist"

export SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR"

cd "$PROJECT_ROOT"

swift build \
  --cache-path "$SWIFTPM_CACHE_DIR" \
  --config-path "$SWIFTPM_CONFIG_DIR" \
  --security-path "$SWIFTPM_SECURITY_DIR"

rm -rf "$DIST_APP_DIR"
mkdir -p "$DIST_APP_DIR/Contents/MacOS" "$DIST_APP_DIR/Contents/Resources"
cp "$EXECUTABLE_PATH" "$DIST_APP_DIR/Contents/MacOS/$APP_NAME"

if [[ -f "$APP_ICON_PNG" ]]; then
  rm -rf "$APP_ICONSET_DIR" "$APP_ICON_ICNS"
  mkdir -p "$APP_ICONSET_DIR"

  sips -z 16 16     "$APP_ICON_PNG" --out "$APP_ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32     "$APP_ICON_PNG" --out "$APP_ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32     "$APP_ICON_PNG" --out "$APP_ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64     "$APP_ICON_PNG" --out "$APP_ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128   "$APP_ICON_PNG" --out "$APP_ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256   "$APP_ICON_PNG" --out "$APP_ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256   "$APP_ICON_PNG" --out "$APP_ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512   "$APP_ICON_PNG" --out "$APP_ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512   "$APP_ICON_PNG" --out "$APP_ICONSET_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$APP_ICON_PNG" --out "$APP_ICONSET_DIR/icon_512x512@2x.png" >/dev/null

  iconutil -c icns "$APP_ICONSET_DIR" -o "$APP_ICON_ICNS"
  cp "$APP_ICON_ICNS" "$DIST_APP_DIR/Contents/Resources/AppIcon.icns"
fi

if [[ -f "$FONT_SOURCE" ]]; then
  mkdir -p "$FONT_DIST_DIR"
  cp "$FONT_SOURCE" "$FONT_DIST_PATH"
fi

if [[ -f "$MENU_FONT_SOURCE" ]]; then
  mkdir -p "$FONT_DIST_DIR"
  cp "$MENU_FONT_SOURCE" "$FONT_DIST_DIR/ChiKareGo.ttf"
fi

if [[ -f "$LABEL_FONT_SOURCE" ]]; then
  mkdir -p "$FONT_DIST_DIR"
  cp "$LABEL_FONT_SOURCE" "$FONT_DIST_DIR/Habbo.ttf"
fi

if git -C "$WORKSPACE_ROOT" rev-parse --verify "$CATALOG_REF" >/dev/null 2>&1; then
  mkdir -p "$CATALOG_DIST_DIR"
  git -C "$WORKSPACE_ROOT" show "$CATALOG_REF:index.json" > "$CATALOG_DIST_DIR/index.json"
  if git -C "$WORKSPACE_ROOT" cat-file -e "$CATALOG_REF:index.html" 2>/dev/null; then
    git -C "$WORKSPACE_ROOT" show "$CATALOG_REF:index.html" > "$CATALOG_DIST_DIR/index.html"
  fi
  git -C "$WORKSPACE_ROOT" archive "$CATALOG_REF" pets | tar -x -C "$CATALOG_DIST_DIR"
elif [[ -f "$WORKSPACE_ROOT/index.json" && -d "$WORKSPACE_ROOT/pets" ]]; then
  mkdir -p "$CATALOG_DIST_DIR"
  cp "$WORKSPACE_ROOT/index.json" "$CATALOG_DIST_DIR/index.json"
  if [[ -f "$WORKSPACE_ROOT/index.html" ]]; then
    cp "$WORKSPACE_ROOT/index.html" "$CATALOG_DIST_DIR/index.html"
  fi
  cp -R "$WORKSPACE_ROOT/pets" "$CATALOG_DIST_DIR/pets"
fi

cat >"$DIST_APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>ATSApplicationFontsPath</key>
  <string>Fonts</string>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>local.codpet.$APP_NAME</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
EOF

echo "App bundle staged at: $DIST_APP_DIR"

if [[ "$RUN_AFTER_BUILD" -eq 0 ]]; then
  exit 0
fi
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
echo "Deploying to /Applications..."
rm -rf "/Applications/$APP_NAME.app"
cp -R "$DIST_APP_DIR" "/Applications/"
/usr/bin/open -n "/Applications/$APP_NAME.app"
echo "Launched $APP_NAME from /Applications"
