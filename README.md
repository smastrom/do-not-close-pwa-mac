# DoNotClosePWA for Mac

Keep macOS web apps running when you close their windows. DoNotClosePWA is a [Hammerspoon](https://www.hammerspoon.org/) Spoon that hides the app when you click its red close button or press `Cmd+W` or `Cmd+Q`. Click its Dock icon to bring it back.

## Behavior

| Action in a detected web app | Result |
| --- | --- |
| Click the red close button | Hide the app, including its other windows |
| `Cmd+W` or `Cmd+Q` | Hide the app |
| `Cmd+Option+Q` | Request a normal quit |
| Close or Quit from the app menu | Use the app's normal behavior |
| Quit from the Dock | Use the app's normal behavior |

The close button also works on background windows. Keyboard shortcuts apply to the active app.

## Install

You need macOS, Hammerspoon, and Accessibility access for Hammerspoon. Safari's Add to Dock web apps require macOS Sonoma (14) or later.

```sh
git clone https://github.com/smastrom/do-not-close-pwa-mac.git
cd do-not-close-pwa-mac
bash install.sh
```

The installer copies the Spoon to `~/.hammerspoon/Spoons/`, adds startup lines to `~/.hammerspoon/init.lua` if needed, and reloads Hammerspoon if it is running. If Hammerspoon is missing, it tries to install it with Homebrew. Without Homebrew, install Hammerspoon yourself and rerun the script.

Enable Hammerspoon in **System Settings > Privacy & Security > Accessibility**. Open Hammerspoon if it is not running, then choose **Reload Config** from its menu bar icon.

### Manual install

With Hammerspoon installed, run these commands from the repository:

```sh
mkdir -p ~/.hammerspoon/Spoons
cp -R DoNotClosePWA.spoon ~/.hammerspoon/Spoons/
```

Add this to `~/.hammerspoon/init.lua`, grant Accessibility access, and reload the config:

```lua
hs.loadSpoon("DoNotClosePWA")
spoon.DoNotClosePWA:start()
```

## App detection

The Spoon recognizes these bundle ID patterns automatically:

| Browser | Bundle ID family |
| --- | --- |
| Safari (Add to Dock) | `com.apple.Safari.WebApp.*` |
| Microsoft Edge | `com.microsoft.edgemac*.app.*` |
| Google Chrome | `com.google.Chrome*.app.*` |
| Brave | `com.brave.Browser*.app.*` |
| Vivaldi | `com.vivaldi.Vivaldi*.app.*` |

The Chromium patterns include channel variants such as Edge Dev and Chrome Beta. Regular browser windows are unaffected.

To include another app, add its exact name or a Lua bundle ID pattern before `start()` in your Hammerspoon config:

```lua
hs.loadSpoon("DoNotClosePWA")
spoon.DoNotClosePWA:addApp("My Custom App")
spoon.DoNotClosePWA:addPattern("^com%.example%.mybrowser.*app%.")
spoon.DoNotClosePWA:start()
```

In a Lua pattern, `%.` matches a literal dot and `.*` matches any sequence of characters. `addApp()` matches the app name exactly.

To read an installed app's bundle ID, replace the path below with its `.app` path:

```sh
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' '/path/to/My App.app/Contents/Info.plist'
```

## Pause and resume

Open the Hammerspoon console from its menu bar icon and run:

```lua
spoon.DoNotClosePWA:stop()
spoon.DoNotClosePWA:start()
```

Use `stop()` to pause interception and `start()` to resume it.

## How it works

A mouse event tap uses Accessibility hit-testing to find the close button and its owning app. When that app matches, the Spoon hides it and consumes the mouse-down and mouse-up events. A keyboard event tap handles the shortcuts above.

App-menu commands, Dock commands, and quit requests from other processes keep their normal behavior. Secure Input can block keyboard interception. If interception stops working, check Hammerspoon's Accessibility permission and reload its config.

## Checks

Run the mocked behavior checks with Lua 5.3 or later from the repository root:

```sh
lua tests/behavior.lua
```

For a live check, open a web app and try the red close button, `Cmd+W`, and `Cmd+Q`. Click its Dock icon after each action to confirm the existing app returns. Try the close button while another app is active, then verify that `Cmd+Option+Q` quits the web app.

## Uninstall

Remove the `DoNotClosePWA` lines from `~/.hammerspoon/init.lua`, then delete the Spoon:

```sh
rm -rf ~/.hammerspoon/Spoons/DoNotClosePWA.spoon
```

Reload Hammerspoon's config to stop any active event taps.

## License

MIT
