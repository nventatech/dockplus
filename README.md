# DockPlus

[![Omarchy](https://img.shields.io/badge/Omarchy-Quattro-1f2335)](https://omarchy.org/)
[![Version](https://img.shields.io/github/v/release/nventatech/dockplus?label=version&color=54a3d8)](https://github.com/nventatech/dockplus/releases)
[![Quickshell](https://img.shields.io/badge/Quickshell-plugin-54a3d8)](https://quickshell.org/)
[![License](https://img.shields.io/badge/license-GPL--3.0-green)](LICENSE)

A Dash to Dock style dock for the Omarchy shell. Hyprland has no minimize, so DockPlus adds one: minimized windows stay on their app icon and come back with a click.

![DockPlus](preview.png)

## Features

- One icon per app: pinned apps, running apps and their minimized windows together.
- Real minimize, including the minimize button of X11 apps such as Steam.
- Live window previews on click or on hover, and a picker for every minimized window.
- Right click menu with the app's own actions (Steam Library, a Brave incognito window).
- Drag any icon to reorder it. Drop files on an app to open them, on a drive to copy them, or on the trash to delete them.
- Trash, removable drives and an applications button, each one optional.
- Bottom, left or right edge, autohide, panel mode, and it never covers a fullscreen game.
- Scroll to cycle windows, a bounce while an app starts and a wiggle when a window asks for attention.
- Settings window with tabs for appearance, position, behavior, animations and items.

## Screenshots

| Previews | Minimized windows |
| --- | --- |
| ![Previews](screenshots/previews.png) | ![Picker](screenshots/picker.png) |

| Settings | Animations |
| --- | --- |
| ![Settings](screenshots/settings-appearance.png) | ![Animations](screenshots/settings-animations.png) |

| Behavior | Left edge |
| --- | --- |
| ![Behavior](screenshots/settings-behavior.png) | ![Left edge](screenshots/dock-left.png) |

## Requirements

Omarchy 4 (Quattro). Everything else ships with Omarchy: `python3` for the X11 minimize helper, `udisks2` and `gvfs` for drives and trash, `gtk-launch` and `uwsm` to start apps.

## Install

```bash
omarchy plugin add https://github.com/nventatech/dockplus --enable
```

Right click any icon and pick **Dock settings** to change anything, or run `omarchy-shell dockplus settings`.

## Keybindings

Add to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + M", "Minimize window", "omarchy-shell dockplus minimize")
o.bind("SUPER + SHIFT + M", "Restore last minimized window", "omarchy-shell dockplus restore")
o.bind("SUPER + ALT + M", "Pick minimized window to restore", "omarchy-shell dockplus pick")
```

The setting **Super + 1-9 opens dock items** binds `SUPER + 1..9` to the dock instead of the Omarchy workspace switch while it is on. It changes the running binds only, never your config files.

Other commands: `omarchy-shell dockplus settings`, `activate <N>`, `pin <appId>`, `unpin <appId>`, `move <appId|@drives|@trash|@apps> <index>` and `position <bottom|left|right>`.

## Configuration

Stored in `~/.config/dockplus/config.json` and edited by the settings window:

- Appearance: `iconSize`, `backgroundOpacity`, `indicatorStyle`, `panelMode`.
- Position: `position`, `monitor`, `autohide`.
- Behavior: `clickAction` (`smart`, `cycle`, `launch`), `previewOnHover`, `superNumbers`.
- Animations: `animations`, `animationSpeed`, `revealStyle` (`slide`, `fade`, `none`), `hoverZoom`, `launchBounce`, `urgentWiggle`, `showDelay`, `hideDelay`.
- Items: `showPinned`, `showAppsButton`, `showTrash`, `showDrives`, `isolateMonitors`, `isolateWorkspaces`.
- `pinned`: dock order, desktop entry ids plus `@drives`, `@trash` and `@apps`.

## Remove

1. Turn off **Super + 1-9 opens dock items** if you turned it on (or run `hyprctl reload` afterwards).
2. Run `omarchy plugin remove io.github.nventatech.dockplus`.
3. Delete `~/.config/dockplus` and any DockPlus lines you added to `bindings.lua`.

## Donate

If DockPlus is useful to you, you can support it through PayPal:

[![Donate via PayPal](https://img.shields.io/badge/PayPal-Donate-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/donate/?business=SR28XBBCYSPHE&no_recurring=0&item_name=Help+me+buy+a+coffee.&currency_code=USD)

<img src="assets/donate-qr.png" width="140" alt="PayPal donation QR code">

## License

[GPL-3.0](LICENSE)
