#!/bin/zsh
# Builds build/NewTextFile.app (host app + Finder Sync extension) and code-signs it.
#
# Signing identity:
#   - Uses your "Apple Development" certificate if one is in the keychain.
#   - Otherwise falls back to ad-hoc signing ("-"), which works fine for local use.
#   - Override with:  SIGN_IDENTITY="<name or SHA-1>" ./scripts/build.sh
set -euo pipefail
cd "${0:A:h}/.."

BUILD_DIR="build"
APP="$BUILD_DIR/NewTextFile.app"
EXT="$APP/Contents/PlugIns/NewTextFileExtension.appex"
MIN_MACOS="12.0"
TARGET="$(uname -m)-apple-macos$MIN_MACOS"

if [[ -z "${SIGN_IDENTITY:-}" ]]; then
  SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
    | awk -F'"' '/Apple Development/ {print $2; exit}')"
  SIGN_IDENTITY="${SIGN_IDENTITY:--}"
fi

if ! command -v swiftc >/dev/null; then
  echo "error: swiftc not found. Install the Command Line Tools with:  xcode-select --install" >&2
  exit 1
fi

echo "==> Building for $TARGET"
rm -rf "$BUILD_DIR"
mkdir -p "$APP/Contents/MacOS" "$EXT/Contents/MacOS"

# Finder extension: an app extension's entry point is NSExtensionMain, not main().
swiftc -O -target "$TARGET" \
  -module-name NewTextFileExtension -parse-as-library -application-extension \
  -Xlinker -e -Xlinker _NSExtensionMain \
  -framework FinderSync -framework Cocoa \
  Sources/FinderExtension/FinderSync.swift \
  -o "$EXT/Contents/MacOS/NewTextFileExtension"

# Host app: only exists to carry and register the extension.
swiftc -O -target "$TARGET" -module-name NewTextFile \
  Sources/App/main.swift \
  -o "$APP/Contents/MacOS/NewTextFile"

cp Resources/Extension-Info.plist "$EXT/Contents/Info.plist"
cp Resources/App-Info.plist "$APP/Contents/Info.plist"

echo "==> Signing with: $SIGN_IDENTITY"
# Sign inside-out: the extension (with its sandbox entitlements) first, then the app.
codesign --force --sign "$SIGN_IDENTITY" --entitlements Resources/Extension.entitlements "$EXT"
codesign --force --sign "$SIGN_IDENTITY" "$APP"
codesign --verify --deep --strict "$APP"

echo "==> Built $APP"
