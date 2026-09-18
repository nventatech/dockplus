# Omarchy Dock

A Dash to Dock style dock for the Omarchy shell. Shows pinned apps, running apps, minimized windows, removable drives, the trash and an applications button.

## Install

```bash
omarchy plugin add <repo-url> --enable
```

## Use

- Click: by default, launch the app, focus its window, or minimize it when it is already focused. With two or more windows, a panel with live previews opens. Settings can switch this to cycling windows or always opening a new window.
- Middle click: open a new window.
- Scroll on an icon: cycle through the app's open windows.
- Right click: the app's own actions (such as Steam Library or a Brave incognito window), then pin, unpin, minimize, close or dock settings.
- Drag any icon along the dock to reorder it: apps, drives, trash and the applications button. Dragging a running app that is not pinned pins it where you drop it.
- Drop files on an app to open them with it, on a drive to copy them there, or on the trash to delete them.
- An icon bounces while its app is starting and wiggles when a window asks for attention.
- Applications button: opens the Omarchy apps menu.
- Trash: shows the item count; click opens it, right click empties it after a second confirming click.
- Removable drives: USB sticks and external disks appear while plugged in. Click mounts and opens; right click unmounts or safely removes the disk.
- Minimized windows stay on their app icon, dimmed. Click to restore to the current workspace. A minimized window that gets focus from elsewhere (a notification, an app activating itself) is restored the same way.
- The minimize button of X11 apps (Steam, Wine apps) works: a small `python3` helper listens for the request on XWayland.
- With autohide on, touch the screen edge where the dock sits to reveal it. It also shows on an empty workspace and never shows over a fullscreen window. On an edge shared with another monitor the pointer crosses over instead of stopping, so prefer an outer edge.
- The picker (`omarchy-shell dock pick`) shows every minimized window as a live card. Arrows or Tab move, Enter restores, Delete closes the window, Esc leaves.

## Keybindings

Hyprland has no minimize, so the dock provides it. Add to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + M", "Minimize window", "omarchy-shell dock minimize")
o.bind("SUPER + SHIFT + M", "Restore last minimized window", "omarchy-shell dock restore")
o.bind("SUPER + ALT + M", "Pick minimized window to restore", "omarchy-shell dock pick")
```

`omarchy-shell dock activate <N>` runs the Nth item of the dock on the focused monitor and shows numbers on the icons. The setting "Super + 1-9 opens dock items" binds it to `SUPER + 1..9` in place of the Omarchy workspace switch while it is on; turning it off reloads Hyprland to bring the workspace keys back. Before removing the plugin, turn it off or run `hyprctl reload`.

Other commands: `omarchy-shell dock settings`, `pin <appId>`, `unpin <appId>`, `move <appId|@drives|@trash|@apps> <index>` and `position <bottom|left|right>`.

## Settings

Stored in `~/.config/omarchy-dock/config.json`:

- Appearance: `iconSize` (24 to 96), `backgroundOpacity` (40 to 100), `position` (`bottom`, `left`, `right`), `monitor` (empty for all, or an output name such as `DP-1`), `indicatorStyle` (`default`, `dots`, `dashes`, `segments`), `panelMode`.
- Behavior: `autohide`, `clickAction` (`smart`, `cycle`, `launch`), `superNumbers`, `isolateMonitors`, `isolateWorkspaces`, `showAppsButton`, `showTrash`, `showDrives`.
- `pinned`: dock order, desktop entry ids plus `@drives`, `@trash` and `@apps`.
