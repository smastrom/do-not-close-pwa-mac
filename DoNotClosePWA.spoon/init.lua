--- === DoNotClosePWA ===
---
--- Previene la chiusura delle finestre PWA su macOS.
--- Quando si clicca il pulsante rosso o si usa Cmd+W/Cmd+Q,
--- la PWA viene nascosta invece di essere chiusa.
---
--- Per chiudere davvero una PWA: Cmd+Option+Q oppure tasto destro Dock > Esci

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "DoNotClosePWA"
obj.version = "1.0"
obj.author = "PWA Guardian"
obj.license = "MIT"

--- DoNotClosePWA.pwaPatterns
--- Bundle ID patterns (Lua patterns) che identificano le PWA.
--- I pattern usano % come escape per i punti letterali.
obj.pwaPatterns = {
    "^com%.google%.Chrome.*app%.",          -- Chrome PWAs (stable, beta, canary)
    "^com%.microsoft%.edgemac.*app%.",       -- Edge PWAs (stable, dev, beta)
    "^com%.brave%.Browser.*app%.",           -- Brave PWAs
    "^com%.vivaldi%.Vivaldi.*app%.",         -- Vivaldi PWAs
}

--- DoNotClosePWA.additionalApps
--- Nomi aggiuntivi di app da trattare come PWA (lista manuale)
obj.additionalApps = {}

local mouseTap = nil
local keyTap = nil
local logger = hs.logger.new("DoNotClosePWA", "info")

--- Controlla se un'app e' una PWA in base al bundle ID o al nome
local function isPWA(app)
    if not app then return false end
    local bid = app:bundleID()
    if bid then
        for _, pattern in ipairs(obj.pwaPatterns) do
            if bid:match(pattern) then return true end
        end
    end
    local name = app:name()
    if name then
        for _, appName in ipairs(obj.additionalApps) do
            if name == appName then return true end
        end
    end
    return false
end

--- Controlla se il click del mouse e' sul pulsante rosso (chiudi) della finestra.
--- Usa prima l'Accessibility API (piu' precisa), poi un fallback a coordinate.
local function isClickOnCloseButton(mousePos, win)
    -- Metodo 1: Accessibility API (trova il pulsante reale)
    local ok, axWin = pcall(hs.axuielement.windowElement, win)
    if ok and axWin then
        local closeBtn = axWin:attributeValue("AXCloseButton")
        if closeBtn then
            local btnPos = closeBtn:attributeValue("AXPosition")
            local btnSize = closeBtn:attributeValue("AXSize")
            if btnPos and btnSize then
                return mousePos.x >= btnPos.x
                    and mousePos.x <= btnPos.x + btnSize.w
                    and mousePos.y >= btnPos.y
                    and mousePos.y <= btnPos.y + btnSize.h
            end
        end
    end

    -- Metodo 2: Fallback basato su coordinate
    -- Il pulsante rosso e' circa a (14, 14) dall'angolo in alto a sinistra della finestra
    local f = win:frame()
    local dx = mousePos.x - (f.x + 14)
    local dy = mousePos.y - (f.y + 14)
    return (dx * dx + dy * dy) <= 144 -- raggio 12px
end

--- DoNotClosePWA:start()
--- Avvia l'intercettazione dei click e delle scorciatoie da tastiera sulle PWA.
function obj:start()
    -- Intercetta i click del mouse sul pulsante rosso
    mouseTap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function(event)
        local app = hs.application.frontmostApplication()
        if not isPWA(app) then return false end

        local win = app:focusedWindow()
        if not win then return false end

        local mousePos = hs.mouse.absolutePosition()

        if isClickOnCloseButton(mousePos, win) then
            logger.i("Intercettato close button su: " .. (app:name() or "?"))
            app:hide()
            return true -- consuma l'evento (il click non raggiunge l'app)
        end
        return false
    end)

    -- Intercetta Cmd+W e Cmd+Q
    keyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
        local app = hs.application.frontmostApplication()
        if not isPWA(app) then return false end

        local flags = event:getFlags()
        local key = event:getKeyCode()

        if not flags.cmd or flags.ctrl then return false end

        -- Cmd+Option+Q = esci davvero dall'app (non intercettare)
        if flags.alt and key == 12 then return false end

        -- Cmd+W (keyCode 13) → nascondi
        -- Cmd+Q (keyCode 12) → nascondi
        if not flags.alt and (key == 13 or key == 12) then
            local label = key == 13 and "W" or "Q"
            logger.i("Intercettato Cmd+" .. label .. " su: " .. (app:name() or "?"))
            app:hide()
            return true
        end

        return false
    end)

    mouseTap:start()
    keyTap:start()
    logger.i("Avviato")
    hs.alert.show("DoNotClosePWA attivo")
    return self
end

--- DoNotClosePWA:stop()
--- Ferma l'intercettazione e ripristina il comportamento normale.
function obj:stop()
    if mouseTap then mouseTap:stop(); mouseTap = nil end
    if keyTap then keyTap:stop(); keyTap = nil end
    logger.i("Fermato")
    hs.alert.show("DoNotClosePWA disattivato")
    return self
end

--- DoNotClosePWA:addApp(name)
--- Aggiunge un'app per nome alla lista delle PWA.
function obj:addApp(name)
    table.insert(self.additionalApps, name)
    logger.i("Aggiunta app: " .. name)
    return self
end

--- DoNotClosePWA:addPattern(pattern)
--- Aggiunge un pattern di bundle ID alla lista.
function obj:addPattern(pattern)
    table.insert(self.pwaPatterns, pattern)
    logger.i("Aggiunto pattern: " .. pattern)
    return self
end

return obj
