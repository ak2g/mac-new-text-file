#!/bin/zsh
# Builds the app, installs it to /Applications, and enables the Finder extension.
# Safe to re-run: it replaces any previous install.
set -euo pipefail
cd "${0:A:h}/.."

EXT_ID="local.newtextfile.app.finder"
DEST="/Applications/NewTextFile.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

./scripts/build.sh

echo "==> Installing to $DEST"
# Unregister and stop any previous copy before replacing it.
pluginkit -e ignore -i "$EXT_ID" 2>/dev/null || true
if [[ -d "$DEST" ]]; then
  pluginkit -r "$DEST/Contents/PlugIns/NewTextFileExtension.appex" 2>/dev/null || true
fi
pkill -f "NewTextFileExtension.appex" 2>/dev/null || true
rm -rf "$DEST"
ditto build/NewTextFile.app "$DEST"

echo "==> Registering and enabling the Finder extension"
"$LSREGISTER" -f "$DEST"
pluginkit -a "$DEST/Contents/PlugIns/NewTextFileExtension.appex"
pluginkit -e use -i "$EXT_ID"

if pluginkit -m -i "$EXT_ID" | grep -q '^+'; then
  echo "==> Done. Right-click inside any Finder window and choose \"New Text File\"."
else
  echo "warning: the extension is installed but not enabled." >&2
  echo "Enable \"NewTextFile\" in System Settings → General → Login Items & Extensions → Extensions." >&2
  exit 1
fi
