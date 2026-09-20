import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
  id: root

  property var dock
  property var order: []
  property var restoring: ({})

  readonly property string workspace: "special:minimized"

  readonly property var list: {
    var known = order
    var windows = dock.toplevels.filter(function(toplevel) { return dock.isMinimized(toplevel) })
    windows.sort(function(a, b) { return known.indexOf(a.address) - known.indexOf(b.address) })
    return windows
  }

  function forget(toplevel) {
    order = order.filter(function(address) { return address !== toplevel.address })
  }

  function minimize(toplevel) {
    if (!toplevel || dock.isMinimized(toplevel)) return
    forget(toplevel)
    order = order.concat([toplevel.address])
    dock.dispatch('hl.dsp.window.move({ window = "address:' + dock.address(toplevel)
      + '", workspace = "' + workspace + '", follow = false })')
  }

  function targetWorkspaceId() {
    var monitor = Hyprland.focusedMonitor
    var current = monitor && monitor.activeWorkspace ? monitor.activeWorkspace : Hyprland.focusedWorkspace
    return current && current.id > 0 ? current.id : 1
  }

  function restore(toplevel) {
    if (!toplevel) return
    forget(toplevel)
    var next = Object.assign({}, restoring)
    next[toplevel.address] = Date.now() + 1500
    restoring = next
    var target = 'window = "address:' + dock.address(toplevel) + '"'
    Quickshell.execDetached(["sh", "-c",
      'hyprctl dispatch "$1" && hyprctl dispatch "$2"\n'
      + 'hyprctl -j monitors | grep -q "\\"special:minimized\\"" && hyprctl dispatch "$3"',
      "sh",
      'hl.dsp.window.move({ ' + target + ', workspace = "' + targetWorkspaceId() + '" })',
      'hl.dsp.focus({ ' + target + ' })',
      'hl.dsp.workspace.toggle_special("minimized")'])
  }

  function minimizeActive() { minimize(Hyprland.activeToplevel) }

  function restoreLast() {
    var windows = list
    if (windows.length > 0) restore(windows[windows.length - 1])
  }

  function onWindowFocused(addressHex) {
    var until = restoring[addressHex]
    if (until && Date.now() < until) return
    var windows = dock.toplevels
    for (var i = 0; i < windows.length; i++)
      if (windows[i].address === addressHex && dock.isMinimized(windows[i])) restore(windows[i])
  }
}
