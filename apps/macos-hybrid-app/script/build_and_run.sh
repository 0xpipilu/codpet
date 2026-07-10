#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="CodpetHybrid"
PRODUCT_NAME="CodpetHybrid"
DEVELOPER_DIR_CANDIDATE="/Applications/Xcode.app/Contents/Developer"
BUILD_DIR="$PROJECT_ROOT/.build"
CACHE_ROOT="$BUILD_DIR/local-cache"
MODULE_CACHE_DIR="$BUILD_DIR/ModuleCache.noindex"
SWIFTPM_CACHE_DIR="$CACHE_ROOT/swiftpm-cache"
SWIFTPM_CONFIG_DIR="$CACHE_ROOT/swiftpm-config"
SWIFTPM_SECURITY_DIR="$CACHE_ROOT/swiftpm-security"
DIST_APP_DIR="$PROJECT_ROOT/dist/$APP_NAME.app"
EXECUTABLE_PATH="$BUILD_DIR/debug/$PRODUCT_NAME"

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

echo "Developer dir: ${DEVELOPER_DIR:-"(system default)"}"
echo "Building $APP_NAME..."

cd "$PROJECT_ROOT"

swift build \
  --cache-path "$SWIFTPM_CACHE_DIR" \
  --config-path "$SWIFTPM_CONFIG_DIR" \
  --security-path "$SWIFTPM_SECURITY_DIR"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Build succeeded but executable was not found at $EXECUTABLE_PATH" >&2
  exit 1
fi

rm -rf "$DIST_APP_DIR"
mkdir -p "$DIST_APP_DIR/Contents/MacOS" "$DIST_APP_DIR/Contents/Resources"
cp "$EXECUTABLE_PATH" "$DIST_APP_DIR/Contents/MacOS/$APP_NAME"

cat >"$DIST_APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
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
  <string>13.0</string>
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
/usr/bin/open -n "$DIST_APP_DIR"
echo "Launched $APP_NAME"
