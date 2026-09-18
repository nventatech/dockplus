import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string configDir: configHome + "/omarchy-dock"
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
  readonly property var clickActions: ["smart", "cycle", "launch"]
  readonly property string clickAction: clickActions.indexOf(adapter.clickAction) !== -1 ? adapter.clickAction : "smart"

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

  function setAutohide(value) { adapter.autohide = value === true }
  function setIconSize(value) { adapter.iconSize = Math.max(minIconSize, Math.min(maxIconSize, Math.round(value))) }
  function setMonitor(name) { adapter.monitor = String(name || "") }
  function setPosition(value) { if (positions.indexOf(value) !== -1) adapter.position = value }

  function setShowAppsButton(value) { adapter.showAppsButton = value === true }
  function setShowTrash(value) { adapter.showTrash = value === true }
  function setShowDrives(value) { adapter.showDrives = value === true }
  function setClickAction(value) { if (clickActions.indexOf(value) !== -1) adapter.clickAction = value }

  function isSpecial(token) { return String(token).charAt(0) === "@" }

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
    if (!token || (isSpecial(token) && specials.indexOf(token) === -1)) return
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
      property string clickAction: "smart"
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
