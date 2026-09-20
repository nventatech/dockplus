import QtQuick
import Quickshell
import Quickshell.Io
import "Logic.js" as Logic

Item {
  id: root

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string configDir: configHome + "/dockplus"
  readonly property string configPath: configDir + "/config.json"

  readonly property int minIconSize: 24
  readonly property int maxIconSize: 96

  readonly property bool autohide: adapter.autohide
  readonly property int iconSize: Math.max(minIconSize, Math.min(maxIconSize, adapter.iconSize))
  readonly property string monitor: adapter.monitor
  readonly property var positions: ["bottom", "left", "right"]
  readonly property string position: positions.indexOf(adapter.position) !== -1 ? adapter.position : "bottom"
  readonly property bool showAppsButton: adapter.showAppsButton
  readonly property bool showTrash: adapter.showTrash
  readonly property bool showDrives: adapter.showDrives
  readonly property bool showPinned: adapter.showPinned
  readonly property int minOpacity: 40
  readonly property var indicatorStyles: ["default", "dots", "dashes", "segments"]
  readonly property string indicatorStyle: indicatorStyles.indexOf(adapter.indicatorStyle) !== -1 ? adapter.indicatorStyle : "default"
  readonly property int backgroundOpacity: Math.max(minOpacity, Math.min(100, adapter.backgroundOpacity))
  readonly property bool panelMode: adapter.panelMode
  readonly property bool blur: adapter.blur
  readonly property bool hideWhileRecording: adapter.hideWhileRecording
  readonly property bool animations: adapter.animations
  readonly property int animationSpeed: Math.max(50, Math.min(200, adapter.animationSpeed))
  readonly property int hoverZoom: Math.max(0, Math.min(30, adapter.hoverZoom))
  readonly property bool launchBounce: adapter.launchBounce
  readonly property bool urgentWiggle: adapter.urgentWiggle
  readonly property var revealStyles: ["slide", "fade", "none"]
  readonly property string revealStyle: revealStyles.indexOf(adapter.revealStyle) !== -1 ? adapter.revealStyle : "slide"
  readonly property int showDelay: Math.max(0, Math.min(500, adapter.showDelay))
  readonly property int hideDelay: Math.max(200, Math.min(2000, adapter.hideDelay))
  readonly property bool isolateMonitors: adapter.isolateMonitors
  readonly property bool superNumbers: adapter.superNumbers
  readonly property bool previewOnHover: adapter.previewOnHover
  readonly property bool isolateWorkspaces: adapter.isolateWorkspaces
  readonly property var clickActions: ["smart", "cycle", "launch"]
  readonly property string clickAction: clickActions.indexOf(adapter.clickAction) !== -1 ? adapter.clickAction : "smart"

  readonly property string folderPrefix: "@folder:"
  readonly property var specials: ["@drives", "@trash", "@apps"]
  readonly property var order: {
    var out = []
    for (var i = 0; i < adapter.pinned.length; i++) {
      var token = String(adapter.pinned[i])
      if (token && out.indexOf(token) === -1) out.push(token)
    }
    for (var j = 0; j < specials.length; j++)
      if (out.indexOf(specials[j]) === -1) out.push(specials[j])
    return out
  }
  readonly property var pinned: order.filter(function(token) { return !root.isSpecial(token) })
  readonly property var folders: order.filter(function(token) { return root.isFolder(token) })

  function setAutohide(value) { adapter.autohide = value === true }
  function setIconSize(value) { adapter.iconSize = Math.max(minIconSize, Math.min(maxIconSize, Math.round(value))) }
  function setMonitor(name) { adapter.monitor = String(name || "") }
  function setPosition(value) { if (positions.indexOf(value) !== -1) adapter.position = value }

  function setShowAppsButton(value) { adapter.showAppsButton = value === true }
  function setShowTrash(value) { adapter.showTrash = value === true }
  function setShowDrives(value) { adapter.showDrives = value === true }
  function setShowPinned(value) { adapter.showPinned = value === true }
  function setIndicatorStyle(value) { if (indicatorStyles.indexOf(value) !== -1) adapter.indicatorStyle = value }
  function setBackgroundOpacity(value) { adapter.backgroundOpacity = Math.max(minOpacity, Math.min(100, Math.round(value))) }
  function setPanelMode(value) { adapter.panelMode = value === true }
  function setBlur(value) { adapter.blur = value === true }
  function setHideWhileRecording(value) { adapter.hideWhileRecording = value === true }
  function setPreviewOnHover(value) { adapter.previewOnHover = value === true }
  function setSuperNumbers(value) { adapter.superNumbers = value === true }
  function setAnimations(value) { adapter.animations = value === true }
  function setAnimationSpeed(value) { adapter.animationSpeed = Math.max(50, Math.min(200, Math.round(value))) }
  function setHoverZoom(value) { adapter.hoverZoom = Math.max(0, Math.min(30, Math.round(value))) }
  function setLaunchBounce(value) { adapter.launchBounce = value === true }
  function setUrgentWiggle(value) { adapter.urgentWiggle = value === true }
  function setRevealStyle(value) { if (revealStyles.indexOf(value) !== -1) adapter.revealStyle = value }
  function setShowDelay(value) { adapter.showDelay = Math.max(0, Math.min(500, Math.round(value))) }
  function setHideDelay(value) { adapter.hideDelay = Math.max(200, Math.min(2000, Math.round(value))) }
  function setIsolateMonitors(value) { adapter.isolateMonitors = value === true }
  function setIsolateWorkspaces(value) { adapter.isolateWorkspaces = value === true }
  function setClickAction(value) { if (clickActions.indexOf(value) !== -1) adapter.clickAction = value }

  function isSpecial(token) { return String(token).charAt(0) === "@" }

  function isFolder(token) { return String(token).indexOf(folderPrefix) === 0 }

  function folderPath(token) { return String(token).substring(folderPrefix.length) }

  function folderToken(path) { return Logic.folderToken(folderPrefix, path) }

  function addFolder(path) {
    var token = folderToken(path)
    if (!path || order.indexOf(token) !== -1) return
    setOrder(order.concat([token]))
  }

  function removeToken(token) {
    if (specials.indexOf(token) !== -1) return
    setOrder(order.filter(function(other) { return other !== token }))
  }

  function isPinned(key) { return pinned.indexOf(key) !== -1 }

  function setOrder(tokens) { adapter.pinned = tokens }

  function pin(key) {
    if (!key || isSpecial(key) || isPinned(key)) return
    var next = order.slice()
    var lastApp = -1
    for (var i = 0; i < next.length; i++) if (!isSpecial(next[i])) lastApp = i
    next.splice(lastApp + 1, 0, key)
    setOrder(next)
  }

  function unpin(key) {
    if (isSpecial(key)) return
    setOrder(order.filter(function(token) { return token !== key }))
  }

  function moveEntry(token, toIndex) {
    if (!token || (isSpecial(token) && specials.indexOf(token) === -1 && !isFolder(token))) return
    var next = order.filter(function(other) { return other !== token })
    var target = Math.max(0, Math.min(next.length, Math.round(toIndex)))
    next.splice(target, 0, token)
    setOrder(next)
  }

  FileView {
    id: file
    path: root.configPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: function(error) {
      if (error === FileViewError.FileNotFound) bootstrap.running = true
    }

    JsonAdapter {
      id: adapter
      property bool autohide: true
      property int iconSize: 48
      property string monitor: ""
      property string position: "bottom"
      property bool showAppsButton: true
      property bool showTrash: true
      property bool showDrives: true
      property bool showPinned: true
      property string clickAction: "smart"
      property bool isolateMonitors: false
      property bool animations: true
      property int animationSpeed: 100
      property int hoverZoom: 10
      property bool launchBounce: true
      property bool urgentWiggle: true
      property string revealStyle: "slide"
      property int showDelay: 120
      property int hideDelay: 450
      property bool superNumbers: false
      property bool previewOnHover: false
      property string indicatorStyle: "default"
      property int backgroundOpacity: 100
      property bool panelMode: false
      property bool blur: false
      property bool hideWhileRecording: true
      property bool isolateWorkspaces: false
      property list<string> pinned: []
    }
  }

  Process {
    id: bootstrap
    command: ["sh", "-c",
      "mkdir -p \"$1\"; cat \"${XDG_CONFIG_HOME:-$HOME/.config}/xdg-terminals.list\" /usr/share/xdg-terminal-exec/xdg-terminals.list 2>/dev/null"
      + " | sed -n 's/^\\([^#[:space:]][^[:space:]]*\\)\\.desktop.*/\\1/p' | head -n1",
      "sh", root.configDir]
    stdout: StdioCollector {
      onStreamFinished: {
        var terminal = String(text || "").trim()
        if (terminal) adapter.pinned = [terminal]
        file.writeAdapter()
      }
    }
  }
}
