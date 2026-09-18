# Omarchy Dock

A Dash to Dock style dock for the Omarchy shell. Shows pinned apps, running apps and minimized windows.

## Install

```bash
omarchy plugin add <repo-url> --enable
```

## Use

- Click: launch the app, focus its window, or minimize it when it is already focused. With two or more windows, a panel with live previews opens so you can pick one.
- Middle click: open a new window.
- Right click: pin, unpin, minimize, close, or open the dock settings.
- Minimized windows stay on their app icon, dimmed and with a dash indicator. Click to restore to the current workspace.
- The minimize button of X11 apps (Steam, Wine apps) works: a small `python3` helper listens for the request on XWayland.
- With autohide on, touch the bottom edge of the screen to reveal the dock. It also stays visible on an empty workspace.

## Keybindings

Hyprland has no minimize, so the dock provides it. Add to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + M", "Minimize window", "omarchy-shell dock minimize")
o.bind("SUPER + SHIFT + M", "Restore last minimized window", "omarchy-shell dock restore")
```

`omarchy-shell dock settings` opens the settings panel.

## Settings

Stored in `~/.config/omarchy-dock/config.json`: `autohide`, `iconSize` (24 to 96), `monitor` (empty for all, or an output name such as `DP-1`) and `pinned` (desktop entry ids).
