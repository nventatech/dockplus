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
  readonly property var pinned: {
    var out = []
    for (var i = 0; i < adapter.pinned.length; i++) out.push(String(adapter.pinned[i]))
    return out
  }

  function setAutohide(value) { adapter.autohide = value === true }
  function setIconSize(value) { adapter.iconSize = Math.max(minIconSize, Math.min(maxIconSize, Math.round(value))) }
  function setMonitor(name) { adapter.monitor = String(name || "") }
  function setPosition(value) { if (positions.indexOf(value) !== -1) adapter.position = value }

  function isPinned(key) { return pinned.indexOf(key) !== -1 }

  function pin(key) {
    if (!key || isPinned(key)) return
    adapter.pinned = pinned.concat([key])
  }

  function unpin(key) {
    adapter.pinned = pinned.filter(function(entry) { return entry !== key })
  }

  function movePinned(key, toIndex) {
    var from = pinned.indexOf(key)
    if (from === -1) return
    var target = Math.max(0, Math.min(pinned.length - 1, Math.round(toIndex)))
    if (target === from) return
    var next = pinned.slice()
    next.splice(from, 1)
    next.splice(target, 0, key)
    adapter.pinned = next
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
