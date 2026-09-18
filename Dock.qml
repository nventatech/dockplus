import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "I18n.js" as I18n

Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string minimizedWorkspace: "special:minimized"
  readonly property string lang: Qt.locale().name.indexOf("pt") === 0 ? "pt" : "en"
  property alias config: dockConfig
  property alias trash: dockTrash
  property var minimizeOrder: []
  property int entriesRevision: 0

  property var clients: ({})
  readonly property var toplevels: Hyprland.toplevels.values.filter(function(toplevel) {
    return root.clients["0x" + toplevel.address] !== undefined
  })

  readonly property var appKeys: {
    var keys = config.pinned.slice()
    for (var i = 0; i < toplevels.length; i++) {
      var key = keyOf(toplevels[i])
      if (keys.indexOf(key) === -1) keys.push(key)
    }
    return keys
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

  function pinApp(appId) {
    var entry = entryFor(appId)
    config.pin(entry ? entry.id : appId)
  }

  function unpinApp(appId) {
    var entry = entryFor(appId)
    config.unpin(entry ? entry.id : appId)
  }

  function movePinnedApp(appId, index) {
    var entry = entryFor(appId)
    config.movePinned(entry ? entry.id : appId, index)
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
    Quickshell.execDetached(["uwsm-app", "--", "gtk-launch", key + ".desktop"])
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

  function activateWindow(toplevel) {
    if (isMinimized(toplevel)) restoreWindow(toplevel)
    else focusWindow(toplevel)
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

  IpcHandler {
    target: "dock"
    function minimize(): void { root.minimizeActive() }
    function restore(): void { root.restoreLast() }
    function pick(): void { root.togglePicker() }
    function settings(): void { root.openSettings() }
    function pin(appId: string): void { root.pinApp(appId) }
    function unpin(appId: string): void { root.unpinApp(appId) }
    function move(appId: string, index: int): void { root.movePinnedApp(appId, index) }
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
