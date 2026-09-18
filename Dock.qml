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
  property int urgentSerial: 0
  property var restoring: ({})

  property var clients: ({})
  readonly property var toplevels: Hyprland.toplevels.values.filter(function(toplevel) {
    return root.clients["0x" + toplevel.address] !== undefined
  })

  function entriesFor(scope) {
    var order = config.order
    var running = []
    for (var i = 0; i < toplevels.length; i++) {
      if (!inScope(toplevels[i], scope)) continue
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

  function localPaths(urls) {
    return urls.filter(function(url) { return url.indexOf("file://") === 0 })
      .map(function(url) { return decodeURIComponent(url.substring(7)) })
  }

  function openWith(key, urls) {
    if (!key || urls.length === 0) return
    markLaunching(key)
    Quickshell.execDetached(["uwsm-app", "--", "gtk-launch", key + ".desktop"].concat(urls))
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

  function moveRendered(list, from, to) {
    var dragged = list[from]
    var anchor = list[to]
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

  function scopeFor(monitor) {
    if (!monitor || (!config.isolateMonitors && !config.isolateWorkspaces)) return null
    return {
      monitorId: config.isolateMonitors ? monitor.id : -1,
      workspaceId: config.isolateWorkspaces && monitor.activeWorkspace ? monitor.activeWorkspace.id : 0
    }
  }

  function inScope(toplevel, scope) {
    if (!scope || isMinimized(toplevel)) return true
    var client = clientOf(toplevel)
    if (!client) return false
    if (scope.monitorId >= 0 && client.monitor !== scope.monitorId) return false
    if (scope.workspaceId !== 0 && (!client.workspace || client.workspace.id !== scope.workspaceId)) return false
    return true
  }

  function windowsOf(key, scope) {
    var open = []
    var minimized = []
    for (var i = 0; i < toplevels.length; i++) {
      var toplevel = toplevels[i]
      if (keyOf(toplevel) !== key || !inScope(toplevel, scope)) continue
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

  function targetWorkspaceId() {
    var monitor = Hyprland.focusedMonitor
    var workspace = monitor && monitor.activeWorkspace ? monitor.activeWorkspace : Hyprland.focusedWorkspace
    return workspace && workspace.id > 0 ? workspace.id : 1
  }

  function restoreWindow(toplevel) {
    if (!toplevel) return
    forgetMinimized(toplevel)
    var next = Object.assign({}, restoring)
    next[toplevel.address] = Date.now() + 1500
    restoring = next
    var target = 'window = "address:' + address(toplevel) + '"'
    Quickshell.execDetached(["sh", "-c",
      'hyprctl dispatch "$1" && hyprctl dispatch "$2"\n'
      + 'hyprctl -j monitors | grep -q "\\"special:minimized\\"" && hyprctl dispatch "$3"',
      "sh",
      'hl.dsp.window.move({ ' + target + ', workspace = "' + targetWorkspaceId() + '" })',
      'hl.dsp.focus({ ' + target + ' })',
      'hl.dsp.workspace.toggle_special("minimized")'])
  }

  function onWindowFocused(addressHex) {
    var until = restoring[addressHex]
    if (until && Date.now() < until) return
    for (var i = 0; i < toplevels.length; i++)
      if (toplevels[i].address === addressHex && isMinimized(toplevels[i])) restoreWindow(toplevels[i])
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

  function newWindow(key) {
    var entry = entryFor(key)
    if (!entry) return
    var command = entry.command
    for (var i = 0; i < entry.actions.length; i++)
      if (entry.actions[i].id === "new-window" && entry.actions[i].command.length > 0) command = entry.actions[i].command
    if (entry.runInTerminal || !command || command.length === 0) {
      launch(key)
      return
    }
    markLaunching(key)
    Quickshell.execDetached(["uwsm-app", "--"].concat(command))
  }

  function markLaunching(key) {
    var next = Object.assign({}, launching)
    next[key] = { count: windowsOf(key).length, until: Date.now() + launchTimeout }
    launching = next
  }

  function isUrgent(key) {
    return windowsOf(key).some(function(toplevel) { return toplevel.urgent && !toplevel.activated })
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

  function activateApp(key, scope) {
    var windows = windowsOf(key, scope)
    if (windows.length === 0) {
      var elsewhere = windowsOf(key)
      if (elsewhere.length > 0) activateWindow(elsewhere[0])
      else launch(key)
      return
    }
    if (windows[0].activated && !isMinimized(windows[0])) minimizeWindow(windows[0])
    else activateWindow(windows[0])
  }

  function openWindowsOf(key, scope) {
    return windowsOf(key, scope).filter(function(toplevel) { return !root.isMinimized(toplevel) })
  }

  function cycleWindows(key, step, scope) {
    var open = openWindowsOf(key, scope)
    var current = -1
    for (var i = 0; i < open.length; i++) if (open[i].activated) current = i
    var next = Logic.nextIndex(open.length, current, step)
    if (next >= 0 && next !== current) focusWindow(open[next])
  }

  function cycleClick(key, scope) {
    var windows = windowsOf(key, scope)
    if (windows.length === 0 && windowsOf(key).length > 0) {
      activateApp(key, scope)
      return
    }
    var open = openWindowsOf(key, scope)
    var focused = -1
    for (var i = 0; i < open.length; i++) if (open[i].activated) focused = i
    var decision = Logic.cycleDecision(windows.length, open.length, focused)
    if (decision === "launch") launch(key)
    else if (decision === "restore") restoreWindow(windows[windows.length - 1])
    else if (decision === "focus") focusWindow(open[0])
    else if (decision === "minimize") minimizeWindow(open[0])
    else cycleWindows(key, 1, scope)
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

  function focusedDock() {
    var windows = docks.instances
    var focused = Hyprland.focusedMonitor
    for (var i = 0; i < windows.length; i++)
      if (focused && windows[i].screen && windows[i].screen.name === focused.name) return windows[i]
    return windows.length > 0 ? windows[0] : null
  }

  function activateIndex(index) {
    var dockWindow = focusedDock()
    if (dockWindow) dockWindow.activateEntry(index - 1)
  }

  function activateEntry(entry, scope) {
    if (!entry) return
    if (entry.kind === "app") cycleClick(entry.key, scope)
    else if (entry.kind === "trash") trash.open()
    else if (entry.kind === "apps") openAppsMenu()
    else if (entry.kind === "drive") drives.open(entry.drive)
  }

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
    function activate(index: int): void { root.activateIndex(index) }
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
      } else if (event.name === "urgent") {
        root.urgentSerial++
      } else if (event.name === "activewindowv2") {
        root.onWindowFocused(String(event.data))
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
    id: docks
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
