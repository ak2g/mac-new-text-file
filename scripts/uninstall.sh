#!/bin/zsh
# Disables the Finder extension and removes /Applications/NewTextFile.app.
EXT_ID="local.newtextfile.app.finder"
DEST="/Applications/NewTextFile.app"

pluginkit -e ignore -i "$EXT_ID" 2>/dev/null
pluginkit -r "$DEST/Contents/PlugIns/NewTextFileExtension.appex" 2>/dev/null
pkill -f "NewTextFileExtension.appex" 2>/dev/null
rm -rf "$DEST"
echo "==> Removed $DEST. The \"New Text File\" menu item is gone."
