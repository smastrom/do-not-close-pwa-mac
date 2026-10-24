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
obj.version = "1.1"
obj.author = "PWA Guardian"
obj.license = "MIT"

--- DoNotClosePWA.pwaPatterns
--- Bundle ID patterns (Lua patterns) that identify PWAs.
--- Patterns use % as escape for literal dots.
obj.pwaPatterns = {
    "^com%.apple%.Safari%.WebApp%.",       -- Safari Add to Dock web apps
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

-- Hit-test the actual element under the pointer, including background windows.
-- Avoid guessed title-bar coordinates: Safari's toolbar geometry can change.
local function closeButtonApplication(position)
    local element = hs.axuielement.systemElementAtPosition(position)
    for _ = 1, 4 do
        if not element then return nil end
        if element:attributeValue("AXSubrole") == "AXCloseButton" then
            local pid = element:pid()
            return pid and hs.application.applicationForPID(pid) or nil
        end
        element = element:attributeValue("AXParent")
    end
end

--- DoNotClosePWA:start()
--- Starts intercepting clicks and keyboard shortcuts on PWAs.
function obj:start()
    -- Calling start twice must not leave orphaned event taps running.
    if mouseTap then mouseTap:stop() end
    if keyTap then keyTap:stop() end
    local swallowMouseUp = false
    mouseTap = hs.eventtap.new({
        hs.eventtap.event.types.leftMouseDown,
        hs.eventtap.event.types.leftMouseUp,
    }, function(event)
        if event:getType() == hs.eventtap.event.types.leftMouseUp then
            local swallow = swallowMouseUp
            swallowMouseUp = false
            return swallow
        end
        swallowMouseUp = false
        local ok, app = pcall(closeButtonApplication, event:location())
        if not ok then
            logger.w("Close-button Accessibility query failed: " .. tostring(app))
            return false
        end
        if not isPWA(app) then return false end
        if not app:hide() then return false end
        swallowMouseUp = true
        logger.i("Intercepted close button on: " .. (app:name() or "?"))
        return true
    end)

    -- Intercept Cmd+W and Cmd+Q
    keyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
        local app = hs.application.frontmostApplication()
        if not isPWA(app) then return false end

        local flags = event:getFlags()
        local key = event:getKeyCode()

        if not flags.cmd or flags.ctrl then return false end

        -- Request a normal quit; passing this shortcut through is not enough
        -- because Safari web apps do not necessarily bind Cmd+Option+Q.
        if flags.alt and not flags.shift and key == hs.keycodes.map.q then
            app:kill()
            return true
        end

        -- Cmd+W (keyCode 13) → hide
        -- Cmd+Q (keyCode 12) → hide
        if not flags.alt and (key == hs.keycodes.map.w or key == hs.keycodes.map.q) then
            local label = key == hs.keycodes.map.w and "W" or "Q"
            logger.i("Intercepted Cmd+" .. label .. " on: " .. (app:name() or "?"))
            return app:hide() and true or false
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
