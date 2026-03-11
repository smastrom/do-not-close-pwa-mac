# DoNotClosePWA

A [Hammerspoon](https://www.hammerspoon.org/) Spoon that makes PWA windows on macOS behave like native apps: **clicking the red close button hides the window instead of quitting the app**.

## The Problem

When you install a web app as a PWA (Progressive Web App) from Edge, Chrome, or other Chromium browsers, macOS treats it as a single-window app. Clicking the red close button - or pressing `Cmd+W` / `Cmd+Q` - **kills the entire process** instead of simply hiding the window, unlike native macOS apps (e.g. Finder, Messages, Music).

## The Solution

DoNotClosePWA intercepts close events on PWA windows and **hides the app instead of closing it**. The app stays alive in the Dock and you can bring it back with a single click - just like a real macOS app.

### What gets intercepted

| Action | Normal PWA behavior | With DoNotClosePWA |
|---|---|---|
| Click red button | Quits the app | Hides the window |
| `Cmd+W` | Quits the app | Hides the window |
| `Cmd+Q` | Quits the app | Hides the window |
| `Cmd+Option+Q` | - | **Actually quits** (escape hatch) |
| Dock > Right-click > Quit | Quits the app | Quits the app (not intercepted) |

## What is a Hammerspoon Spoon?

[Hammerspoon](https://www.hammerspoon.org/) is a free, open-source macOS automation tool that lets you write Lua scripts to control your system. A **Spoon** is Hammerspoon's plugin format - a self-contained module that you drop into `~/.hammerspoon/Spoons/` and load from your config.

Think of it like: Hammerspoon is the engine, Spoons are the plugins.

## Installation

### Quick install

```bash
git clone https://github.com/YOUR_USERNAME/do-not-close-pwa.git
cd do-not-close-pwa
bash install.sh
```

The install script will:
1. Install Hammerspoon via Homebrew (if not already installed)
2. Copy the Spoon to `~/.hammerspoon/Spoons/`
3. Add the startup config to `~/.hammerspoon/init.lua`
4. Reload Hammerspoon if it's running

### Manual install

1. Copy `DoNotClosePWA.spoon/` to `~/.hammerspoon/Spoons/`
2. Add this to your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("DoNotClosePWA")
spoon.DoNotClosePWA:start()
```

3. Reload Hammerspoon (menu bar icon > Reload Config)

### Grant Accessibility permissions

Hammerspoon needs Accessibility access to intercept clicks and keyboard shortcuts:

**System Settings > Privacy & Security > Accessibility > enable Hammerspoon**

Without this, the Spoon won't be able to intercept any events.

## Supported Browsers

PWAs are detected automatically by their **bundle ID pattern**. The following browsers are supported out of the box:

| Browser | Bundle ID pattern | Example |
|---|---|---|
| **Microsoft Edge** (all channels) | `com.microsoft.edgemac*.app.*` | `com.microsoft.edgemac.Dev.app.ingmankjgobdmjekjjochfcnpomocinf` |
| **Google Chrome** (all channels) | `com.google.Chrome*.app.*` | `com.google.Chrome.app.abcdef123456` |
| **Brave** | `com.brave.Browser*.app.*` | `com.brave.Browser.app.abcdef123456` |
| **Vivaldi** | `com.vivaldi.Vivaldi*.app.*` | `com.vivaldi.Vivaldi.app.abcdef123456` |

This means **all PWAs from these browsers are automatically handled** - no manual configuration needed.

## Configuration

### Adding an app by name

If a PWA is not detected automatically, you can add it by name in your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("DoNotClosePWA")
spoon.DoNotClosePWA:addApp("My Custom App")
spoon.DoNotClosePWA:start()
```

### Adding a custom bundle ID pattern

To support a new browser or a custom Chromium build:

```lua
hs.loadSpoon("DoNotClosePWA")
spoon.DoNotClosePWA:addPattern("^com%.example%.mybrowser.*app%.")
spoon.DoNotClosePWA:start()
```

> **Note:** Lua patterns use `%` to escape special characters. A literal dot is `%.`, and `.*` matches any sequence of characters.

### Finding a PWA's bundle ID

To find the bundle ID of any installed PWA:

```bash
# List all Edge PWAs
for app in ~/Applications/Edge\ Apps.localized/*.app; do
    /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app/Contents/Info.plist" 2>/dev/null
done

# List all Chrome PWAs
for app in ~/Applications/Chrome\ Apps.localized/*.app; do
    /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app/Contents/Info.plist" 2>/dev/null
done
```

### Temporarily disabling

From the Hammerspoon console (menu bar icon > Console):

```lua
spoon.DoNotClosePWA:stop()   -- disable
spoon.DoNotClosePWA:start()  -- re-enable
```

## How It Works

The Spoon uses two Hammerspoon [event taps](https://www.hammerspoon.org/docs/hs.eventtap.html):

1. **Mouse tap** - listens for `leftMouseDown` events. When a click occurs, it checks if the frontmost app is a PWA and whether the click landed on the window's close button (using the macOS Accessibility API to find the real button position). If so, it hides the app and swallows the click.

2. **Keyboard tap** - listens for `keyDown` events. When `Cmd+W` or `Cmd+Q` is pressed in a PWA, it hides the app instead. `Cmd+Option+Q` is left untouched as an escape hatch to actually quit.

## Requirements

- macOS 12+ (Monterey or later)
- [Hammerspoon](https://www.hammerspoon.org/) (installable via `brew install --cask hammerspoon`)
- Accessibility permissions for Hammerspoon

## License

MIT
