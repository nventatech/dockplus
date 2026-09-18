import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property bool active: true
  property int count: 0

  readonly property bool full: count > 0

  function refresh() {
    if (active && !listing.running) listing.running = true
  }

  function open() {
    Quickshell.execDetached(["gio", "open", "trash:///"])
    refresh()
  }

  function trashFiles(urls) {
    if (urls.length === 0) return
    trashing.command = ["gio", "trash", "--"].concat(urls)
    trashing.running = true
  }

  function empty() {
    emptying.running = true
  }

  onActiveChanged: refresh()

  Process {
    id: listing
    command: ["gio", "trash", "--list"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.count = String(text || "").split("\n").filter(function(line) { return line.trim() !== "" }).length
      }
    }
  }

  Process {
    id: trashing
    onExited: root.refresh()
  }

  Process {
    id: emptying
    command: ["gio", "trash", "--empty"]
    onExited: root.refresh()
  }

  Timer {
    interval: 10000
    running: root.active
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
