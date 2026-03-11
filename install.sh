#!/bin/bash
# ============================================================
# DoNotClosePWA - Script di installazione
# Installa lo Spoon Hammerspoon che previene la chiusura delle PWA
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPOON_SRC="$SCRIPT_DIR/DoNotClosePWA.spoon"
SPOON_DST="$HOME/.hammerspoon/Spoons/DoNotClosePWA.spoon"
INIT_FILE="$HOME/.hammerspoon/init.lua"

echo "=== DoNotClosePWA - Installazione ==="
echo ""

# 1. Controlla se Hammerspoon e' installato
if [ -d "/Applications/Hammerspoon.app" ] || [ -d "$HOME/Applications/Hammerspoon.app" ]; then
    echo "[OK] Hammerspoon trovato"
else
    echo "[!] Hammerspoon non trovato."
    echo ""
    if command -v brew &>/dev/null; then
        echo "Installo Hammerspoon con Homebrew..."
        brew install --cask hammerspoon
        echo "[OK] Hammerspoon installato"
    else
        echo "Opzioni:"
        echo "  1. Installa Homebrew (https://brew.sh) e poi riesegui questo script"
        echo "  2. Scarica Hammerspoon da: https://www.hammerspoon.org/"
        echo ""
        echo "Dopo l'installazione, riesegui: bash install.sh"
        exit 1
    fi
fi

# 2. Crea le directory necessarie
mkdir -p "$HOME/.hammerspoon/Spoons"

# 3. Copia lo Spoon
if [ -d "$SPOON_DST" ]; then
    echo "[~] Aggiorno lo Spoon esistente..."
    rm -rf "$SPOON_DST"
fi
cp -r "$SPOON_SRC" "$SPOON_DST"
echo "[OK] Spoon copiato in $SPOON_DST"

# 4. Configura init.lua
SPOON_CONFIG='-- DoNotClosePWA: le PWA si nascondono invece di chiudersi
hs.loadSpoon("DoNotClosePWA")
spoon.DoNotClosePWA:start()
-- Per aggiungere PWA per nome: spoon.DoNotClosePWA:addApp("NomeApp")
-- Per disattivare: spoon.DoNotClosePWA:stop()
-- Per chiudere davvero una PWA: Cmd+Option+Q oppure Dock > tasto destro > Esci'

if [ -f "$INIT_FILE" ]; then
    if grep -q "DoNotClosePWA" "$INIT_FILE"; then
        echo "[OK] Configurazione gia' presente in init.lua"
    else
        echo "" >> "$INIT_FILE"
        echo "$SPOON_CONFIG" >> "$INIT_FILE"
        echo "[OK] Configurazione aggiunta a init.lua"
    fi
else
    echo "$SPOON_CONFIG" > "$INIT_FILE"
    echo "[OK] Creato init.lua con configurazione"
fi

# 5. Ricarica Hammerspoon (se in esecuzione)
if pgrep -q Hammerspoon; then
    echo ""
    echo "Ricarico la configurazione di Hammerspoon..."
    open -g "hammerspoon://reloadconfig" 2>/dev/null || true
    echo "[OK] Configurazione ricaricata"
else
    echo ""
    echo "[!] Hammerspoon non e' in esecuzione."
    echo "    Aprilo e poi ricarica la configurazione (icona menu > Reload Config)"
fi

echo ""
echo "============================================"
echo " Installazione completata!"
echo "============================================"
echo ""
echo " Come funziona:"
echo "   - Click sul pulsante rosso di una PWA  -> la nasconde"
echo "   - Cmd+W su una PWA                     -> la nasconde"
echo "   - Cmd+Q su una PWA                     -> la nasconde"
echo "   - Cmd+Option+Q su una PWA              -> la chiude davvero"
echo "   - Dock > tasto destro > Esci           -> la chiude davvero"
echo ""
echo " IMPORTANTE: Hammerspoon ha bisogno dei permessi di Accessibilita'."
echo " Vai in: Impostazioni di Sistema > Privacy e Sicurezza > Accessibilita'"
echo " e assicurati che Hammerspoon sia abilitato."
echo ""
echo " PWA Edge Dev rilevate automaticamente:"

# Mostra le PWA trovate
for app in "$HOME/Applications/Edge Apps.localized/"*.app; do
    if [ -f "$app/Contents/Info.plist" ]; then
        name=$(basename "$app" .app)
        echo "   - $name"
    fi
done
