import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "I18n.js" as I18n
import "Logic.js" as Logic

Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string minimizedWorkspace: "special:minimized"
  readonly property string lang: Qt.locale().name.indexOf("pt") === 0 ? "pt" : "en"
  property alias config: dockConfig
  property alias trash: dockTrash
  property alias drives: dockDrives
  property var minimizeOrder: []
  property int entriesRevision: 0
  readonly property int maxActions: 10
  readonly property int launchTimeout: 10000
  property var launching: ({})

  property var clients: ({})
  readonly property var toplevels: Hyprland.toplevels.values.filter(function(toplevel) {
    return root.clients["0x" + toplevel.address] !== undefined
  })

  readonly property var entries: {
    var order = config.order
    var running = []
    for (var i = 0; i < toplevels.length; i++) {
      var key = keyOf(toplevels[i])
      if (order.indexOf(key) === -1 && running.indexOf(key) === -1) running.push(key)
    }
    var lastApp = -1
    for (var j = 0; j < order.length; j++) if (!config.isSpecial(order[j])) lastApp = j
    var out = []
    function pushRunning() {
      for (var r = 0; r < running.length; r++) out.push({ kind: "app", token: "", key: running[r] })
    }
    if (lastApp === -1) pushRunning()
    for (var k = 0; k < order.length; k++) {
      var token = order[k]
      if (token === "@trash") {
        if (config.showTrash) out.push({ kind: "trash", token: token, key: token })
      } else if (token === "@apps") {
        if (config.showAppsButton) out.push({ kind: "apps", token: token, key: token })
      } else if (token === "@drives") {
        var list = config.showDrives ? drives.drives : []
        for (var d = 0; d < list.length; d++) out.push({ kind: "drive", token: token, key: list[d].device + "|" + list[d].mountpoint, drive: list[d] })
      } else if (!config.isSpecial(token)) {
        out.push({ kind: "app", token: token, key: token })
      }
      if (k === lastApp) pushRunning()
    }
    return out
  }

  readonly property var minimizedWindows: {
    var order = minimizeOrder
    var windows = toplevels.filter(function(toplevel) { return isMinimized(toplevel) })
    windows.sort(function(a, b) { return order.indexOf(a.address) - order.indexOf(b.address) })
    return windows
  }

  function tr(key) { return I18n.tr(lang, key) }

  function open(payload) { openSettings() }
  function openSettings() { settings.opened = true }
  function close() { settings.opened = false }

  function clientOf(toplevel) {
    return toplevel ? clients["0x" + toplevel.address] || null : null
  }

  function applyClients(text) {
    var list = []
    try { list = JSON.parse(text) } catch (error) { return }
    var next = ({})
    for (var i = 0; i < list.length; i++) next[list[i].address] = list[i]
    clients = next
  }

  function refreshClients() {
    refreshSoon.restart()
    refreshLate.restart()
  }

  function appIdOf(toplevel) {
    if (!toplevel) return ""
    if (toplevel.wayland && toplevel.wayland.appId) return toplevel.wayland.appId
    var client = clientOf(toplevel)
    return client && client.class ? String(client.class) : ""
  }

  function entryFor(appId) {
    if (!appId || entriesRevision < 0) return null
    return DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId)
  }

  function actionsFor(key) {
    var entry = entryFor(key)
    if (!entry) return []
    var main = JSON.stringify(entry.command)
    var out = []
    for (var i = 0; i < entry.actions.length && out.length < maxActions; i++) {
      var action = entry.actions[i]
      if (JSON.stringify(action.command) !== main) out.push(action)
    }
    return out
  }

  function runAction(action) {
    if (!action) return
    if (action.command && action.command.length > 0)
      Quickshell.execDetached(["uwsm-app", "--"].concat(action.command))
    else
      action.execute()
  }

  function pinApp(appId) {
    var entry = entryFor(appId)
    config.pin(entry ? entry.id : appId)
  }

  function unpinApp(appId) {
    var entry = entryFor(appId)
    config.unpin(entry ? entry.id : appId)
  }

  function moveEntry(name, index) {
    var entry = config.isSpecial(name) ? null : entryFor(name)
    config.moveEntry(entry ? entry.id : name, index)
  }

  function moveRendered(from, to) {
    var dragged = entries[from]
    var anchor = entries[to]
    if (!dragged || !anchor || from === to) return
    var token = dragged.token || dragged.key
    var order = config.order.filter(function(other) { return other !== token })
    var anchorToken = anchor.token
    if (anchorToken === token) return
    var after = to > from
    if (!anchorToken) {
      anchorToken = config.pinned.length > 0 ? config.pinned[config.pinned.length - 1] : ""
      if (anchorToken === token) anchorToken = config.pinned.length > 1 ? config.pinned[config.pinned.length - 2] : ""
      after = true
    }
    var index = anchorToken ? order.indexOf(anchorToken) : -1
    order.splice(index === -1 ? 0 : (after ? index + 1 : index), 0, token)
    config.setOrder(order)
  }

  function keyOf(toplevel) {
    var appId = appIdOf(toplevel)
    var entry = entryFor(appId)
    if (entry) return entry.id
    return appId || ("address:" + toplevel.address)
  }

  function workspaceNameOf(toplevel) {
    var client = clientOf(toplevel)
    return client && client.workspace ? String(client.workspace.name || "") : ""
  }

  function isMinimized(toplevel) {
    return workspaceNameOf(toplevel) === minimizedWorkspace
  }

  function windowsOf(key) {
    var open = []
    var minimized = []
    for (var i = 0; i < toplevels.length; i++) {
      var toplevel = toplevels[i]
      if (keyOf(toplevel) !== key) continue
      if (isMinimized(toplevel)) minimized.push(toplevel)
      else open.push(toplevel)
    }
    return open.concat(minimized)
  }

  function iconFor(appId, entry) {
    var steam = /^steam_app_(\d+)$/.exec(appId || "")
    var candidates = []
    if (entry && entry.icon) candidates.push(entry.icon)
    if (steam) candidates.push("steam_icon_" + steam[1], "steam")
    if (appId) candidates.push(appId, appId.toLowerCase())
    for (var i = 0; i < candidates.length; i++) {
      var path = Quickshell.iconPath(candidates[i], true)
      if (path) return path
    }
    return Quickshell.iconPath("application-x-executable")
  }

  function address(toplevel) { return "0x" + toplevel.address }

  function dispatch(expression) {
    Quickshell.execDetached(["hyprctl", "dispatch", expression])
  }

  function focusWindow(toplevel) {
    dispatch('hl.dsp.focus({ window = "address:' + address(toplevel) + '" })')
  }

  function closeWindow(toplevel) {
    dispatch('hl.dsp.window.close({ window = "address:' + address(toplevel) + '" })')
  }

  function forgetMinimized(toplevel) {
    minimizeOrder = minimizeOrder.filter(function(entry) { return entry !== toplevel.address })
  }

  function minimizeWindow(toplevel) {
    if (!toplevel || isMinimized(toplevel)) return
    forgetMinimized(toplevel)
    minimizeOrder = minimizeOrder.concat([toplevel.address])
    dispatch('hl.dsp.window.move({ window = "address:' + address(toplevel)
      + '", workspace = "' + minimizedWorkspace + '", follow = false })')
  }

  function restoreWindow(toplevel) {
    if (!toplevel) return
    forgetMinimized(toplevel)
    var workspace = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    var target = 'window = "address:' + address(toplevel) + '"'
    Quickshell.execDetached(["sh", "-c", 'hyprctl dispatch "$1" && hyprctl dispatch "$2"', "sh",
      'hl.dsp.window.move({ ' + target + ', workspace = "' + workspace + '" })',
      'hl.dsp.focus({ ' + target + ' })'])
  }

  function x11Toplevel(pid, title) {
    var candidates = toplevels.filter(function(toplevel) {
      var client = clientOf(toplevel)
      if (!client || client.xwayland !== true) return false
      return pid > 0 ? client.pid === pid : toplevel.title === title
    })
    for (var i = 0; i < candidates.length; i++) if (candidates[i].title === title) return candidates[i]
    return candidates.length > 0 ? candidates[0] : null
  }

  function minimizeActive() {
    minimizeWindow(Hyprland.activeToplevel)
  }

  function restoreLast() {
    var windows = minimizedWindows
    if (windows.length > 0) restoreWindow(windows[windows.length - 1])
  }

  function openAppsMenu() {
    Quickshell.execDetached(["omarchy-menu", "toggle", "apps"])
  }

  function launch(key) {
    if (!key) return
    markLaunching(key)
    Quickshell.execDetached(["uwsm-app", "--", "gtk-launch", key + ".desktop"])
  }

  function markLaunching(key) {
    var next = Object.assign({}, launching)
    next[key] = { count: windowsOf(key).length, until: Date.now() + launchTimeout }
    launching = next
  }

  function isLaunching(key) {
    var info = launching[key]
    return !!info && Date.now() < info.until && windowsOf(key).length <= info.count
  }

  function pruneLaunching() {
    var next = ({})
    var changed = false
    for (var key in launching) {
      if (isLaunching(key)) next[key] = launching[key]
      else changed = true
    }
    if (changed) launching = next
  }

  function activateApp(key) {
    var windows = windowsOf(key)
    if (windows.length === 0) {
      launch(key)
      return
    }
    if (windows[0].activated && !isMinimized(windows[0])) minimizeWindow(windows[0])
    else activateWindow(windows[0])
  }

  function openWindowsOf(key) {
    return windowsOf(key).filter(function(toplevel) { return !root.isMinimized(toplevel) })
  }

  function cycleWindows(key, step) {
    var open = openWindowsOf(key)
    var current = -1
    for (var i = 0; i < open.length; i++) if (open[i].activated) current = i
    var next = Logic.nextIndex(open.length, current, step)
    if (next >= 0 && next !== current) focusWindow(open[next])
  }

  function activateWindow(toplevel) {
    if (isMinimized(toplevel)) restoreWindow(toplevel)
    else focusWindow(toplevel)
  }

  function fullscreenOn(monitorName) {
    var monitors = Hyprland.monitors.values
    for (var i = 0; i < monitors.length; i++) {
      if (monitors[i].name !== monitorName) continue
      var workspace = monitors[i].activeWorkspace
      return workspace ? workspace.hasFullscreen === true : false
    }
    return false
  }

  function focusedScreen() {
    var focused = Hyprland.focusedMonitor
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++)
      if (focused && screens[i].name === focused.name) return screens[i]
    return screens.length > 0 ? screens[0] : null
  }

  function togglePicker() { picker.toggle() }

  function screenEnabled(screen) {
    return config.monitor === "" || config.monitor === screen.name
  }

  Config { id: dockConfig }

  Trash {
    id: dockTrash
    active: dockConfig.showTrash
  }

  Drives {
    id: dockDrives
    active: dockConfig.showDrives
  }

  IpcHandler {
    target: "dock"
    function minimize(): void { root.minimizeActive() }
    function restore(): void { root.restoreLast() }
    function pick(): void { root.togglePicker() }
    function settings(): void { root.openSettings() }
    function pin(appId: string): void { root.pinApp(appId) }
    function unpin(appId: string): void { root.unpinApp(appId) }
    function move(name: string, index: int): void { root.moveEntry(name, index) }
    function position(value: string): void { root.config.setPosition(value) }
  }

  Connections {
    target: DesktopEntries
    function onApplicationsChanged() { root.entriesRevision++ }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "movewindowv2" || event.name === "openwindow" || event.name === "closewindow") {
        root.refreshClients()
      } else if (event.name === "minimized") {
        var parts = String(event.data).split(",")
        if (parts[1] !== "1") return
        for (var i = 0; i < root.toplevels.length; i++)
          if (root.toplevels[i].address === parts[0]) root.minimizeWindow(root.toplevels[i])
      }
    }
  }

  Process {
    id: x11Watch
    running: true
    command: ["python3", Qt.resolvedUrl("x11-minimize-watch.py").toString().replace("file://", "")]
    stdout: SplitParser {
      onRead: function(line) {
        var request = null
        try { request = JSON.parse(line) } catch (error) { return }
        root.minimizeWindow(root.x11Toplevel(Number(request.pid) || 0, String(request.title || "")))
      }
    }
    onExited: x11WatchRestart.restart()
  }

  Timer {
    id: x11WatchRestart
    interval: 5000
    onTriggered: x11Watch.running = true
  }

  Process {
    id: clientsQuery
    command: ["hyprctl", "-j", "clients"]
    stdout: StdioCollector { onStreamFinished: root.applyClients(text) }
  }

  Timer {
    interval: 500
    repeat: true
    running: Object.keys(root.launching).length > 0
    onTriggered: root.pruneLaunching()
  }

  Timer { id: refreshSoon; interval: 60; onTriggered: clientsQuery.running = true }
  Timer { id: refreshLate; interval: 700; onTriggered: clientsQuery.running = true }

  Component.onCompleted: clientsQuery.running = true

  Variants {
    model: {
      var position = root.config.position
      return Quickshell.screens.filter(function(screen) { return root.screenEnabled(screen) })
        .map(function(screen) { return { screen: screen, position: position } })
    }
    DockWindow { dock: root }
  }

  DockSettings {
    id: settings
    dock: root
  }

  DockPicker {
    id: picker
    dock: root
  }
}
