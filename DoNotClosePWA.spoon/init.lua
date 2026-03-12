--- === DoNotClosePWA ===
---
--- Prevents PWA windows from being closed on macOS.
--- When clicking the red close button or using Cmd+W/Cmd+Q,
--- the PWA is hidden instead of being closed.
---
--- To actually close a PWA: Cmd+Option+Q or right-click Dock > Quit

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "DoNotClosePWA"
obj.version = "1.0"
obj.author = "PWA Guardian"
obj.license = "MIT"

--- DoNotClosePWA.pwaPatterns
--- Bundle ID patterns (Lua patterns) that identify PWAs.
--- Patterns use % as escape for literal dots.
obj.pwaPatterns = {
    "^com%.google%.Chrome.*app%.",          -- Chrome PWAs (stable, beta, canary)
    "^com%.microsoft%.edgemac.*app%.",       -- Edge PWAs (stable, dev, beta)
    "^com%.brave%.Browser.*app%.",           -- Brave PWAs
    "^com%.vivaldi%.Vivaldi.*app%.",         -- Vivaldi PWAs
}

--- DoNotClosePWA.additionalApps
--- Additional app names to treat as PWAs (manual list)
obj.additionalApps = {}

local mouseTap = nil
local keyTap = nil
local logger = hs.logger.new("DoNotClosePWA", "info")

--- Checks if an app is a PWA based on its bundle ID or name
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

--- Checks if the mouse click is on the window's close (red) button.
--- Uses Accessibility API first (more accurate), then falls back to coordinates.
local function isClickOnCloseButton(mousePos, win)
    -- Method 1: Accessibility API (finds the real button)
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

    -- Method 2: Coordinate-based fallback
    -- The red button is approximately at (14, 14) from the top-left corner of the window
    local f = win:frame()
    local dx = mousePos.x - (f.x + 14)
    local dy = mousePos.y - (f.y + 14)
    return (dx * dx + dy * dy) <= 144 -- radius 12px
end

--- DoNotClosePWA:start()
--- Starts intercepting clicks and keyboard shortcuts on PWAs.
function obj:start()
    -- Intercept mouse clicks on the red close button
    mouseTap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function(event)
        local app = hs.application.frontmostApplication()
        if not isPWA(app) then return false end

        local win = app:focusedWindow()
        if not win then return false end

        local mousePos = hs.mouse.absolutePosition()

        if isClickOnCloseButton(mousePos, win) then
            logger.i("Intercepted close button on: " .. (app:name() or "?"))
            app:hide()
            return true -- consume the event (click does not reach the app)
        end
        return false
    end)

    -- Intercept Cmd+W and Cmd+Q
    keyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
        local app = hs.application.frontmostApplication()
        if not isPWA(app) then return false end

        local flags = event:getFlags()
        local key = event:getKeyCode()

        if not flags.cmd or flags.ctrl then return false end

        -- Cmd+Option+Q = actually quit the app (do not intercept)
        if flags.alt and key == 12 then return false end

        -- Cmd+W (keyCode 13) → hide
        -- Cmd+Q (keyCode 12) → hide
        if not flags.alt and (key == 13 or key == 12) then
            local label = key == 13 and "W" or "Q"
            logger.i("Intercepted Cmd+" .. label .. " on: " .. (app:name() or "?"))
            app:hide()
            return true
        end

        return false
    end)

    mouseTap:start()
    keyTap:start()
    logger.i("Started")
    hs.alert.show("DoNotClosePWA active")
    return self
end

--- DoNotClosePWA:stop()
--- Stops interception and restores normal behavior.
function obj:stop()
    if mouseTap then mouseTap:stop(); mouseTap = nil end
    if keyTap then keyTap:stop(); keyTap = nil end
    logger.i("Stopped")
    hs.alert.show("DoNotClosePWA disabled")
    return self
end

--- DoNotClosePWA:addApp(name)
--- Adds an app by name to the PWA list.
function obj:addApp(name)
    table.insert(self.additionalApps, name)
    logger.i("Added app: " .. name)
    return self
end

--- DoNotClosePWA:addPattern(pattern)
--- Adds a bundle ID pattern to the list.
function obj:addPattern(pattern)
    table.insert(self.pwaPatterns, pattern)
    logger.i("Added pattern: " .. pattern)
    return self
end

return obj
