#!/bin/bash
# ============================================================
# DoNotClosePWA - Installation script
# Installs the Hammerspoon Spoon that prevents PWAs from closing
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPOON_SRC="$SCRIPT_DIR/DoNotClosePWA.spoon"
SPOON_DST="$HOME/.hammerspoon/Spoons/DoNotClosePWA.spoon"
INIT_FILE="$HOME/.hammerspoon/init.lua"

echo "=== DoNotClosePWA - Installation ==="
echo ""

# 1. Check if Hammerspoon is installed
if [ -d "/Applications/Hammerspoon.app" ] || [ -d "$HOME/Applications/Hammerspoon.app" ]; then
    echo "[OK] Hammerspoon found"
else
    echo "[!] Hammerspoon not found."
    echo ""
    if command -v brew &>/dev/null; then
        echo "Installing Hammerspoon with Homebrew..."
        brew install --cask hammerspoon
        echo "[OK] Hammerspoon installed"
    else
        echo "Options:"
        echo "  1. Install Homebrew (https://brew.sh) and then re-run this script"
        echo "  2. Download Hammerspoon from: https://www.hammerspoon.org/"
        echo ""
        echo "After installation, re-run: bash install.sh"
        exit 1
    fi
fi

# 2. Create necessary directories
mkdir -p "$HOME/.hammerspoon/Spoons"

# 3. Copy the Spoon
if [ -d "$SPOON_DST" ]; then
    echo "[~] Updating existing Spoon..."
    rm -rf "$SPOON_DST"
fi
cp -r "$SPOON_SRC" "$SPOON_DST"
echo "[OK] Spoon copied to $SPOON_DST"

# 4. Configure init.lua
SPOON_CONFIG='-- DoNotClosePWA: PWAs are hidden instead of being closed
hs.loadSpoon("DoNotClosePWA")
spoon.DoNotClosePWA:start()
-- To add a PWA by name: spoon.DoNotClosePWA:addApp("AppName")
-- To disable: spoon.DoNotClosePWA:stop()
-- To actually close a PWA: Cmd+Option+Q or Dock > right-click > Quit'

if [ -f "$INIT_FILE" ]; then
    if grep -q "DoNotClosePWA" "$INIT_FILE"; then
        echo "[OK] Configuration already present in init.lua"
    else
        echo "" >> "$INIT_FILE"
        echo "$SPOON_CONFIG" >> "$INIT_FILE"
        echo "[OK] Configuration added to init.lua"
    fi
else
    echo "$SPOON_CONFIG" > "$INIT_FILE"
    echo "[OK] Created init.lua with configuration"
fi

# 5. Reload Hammerspoon (if running)
if pgrep -q Hammerspoon; then
    echo ""
    echo "Reloading Hammerspoon configuration..."
    open -g "hammerspoon://reloadconfig" 2>/dev/null || true
    echo "[OK] Configuration reloaded"
else
    echo ""
    echo "[!] Hammerspoon is not running."
    echo "    Open it and then reload the configuration (menu bar icon > Reload Config)"
fi

echo ""
echo "============================================"
echo " Installation complete!"
echo "============================================"
echo ""
echo " How it works:"
echo "   - Click the red button on a PWA          -> hides it"
echo "   - Cmd+W on a PWA                         -> hides it"
echo "   - Cmd+Q on a PWA                         -> hides it"
echo "   - Cmd+Option+Q on a PWA                  -> actually closes it"
echo "   - Dock > right-click > Quit              -> actually closes it"
echo ""
echo " IMPORTANT: Hammerspoon needs Accessibility permissions."
echo " Go to: System Settings > Privacy & Security > Accessibility"
echo " and make sure Hammerspoon is enabled."
echo ""
echo " Automatically detected Edge Dev PWAs:"

# Show found PWAs
for app in "$HOME/Applications/Edge Apps.localized/"*.app; do
    if [ -f "$app/Contents/Info.plist" ]; then
        name=$(basename "$app" .app)
        echo "   - $name"
    fi
done
