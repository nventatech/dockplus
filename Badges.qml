import QtQuick
import Quickshell
import Quickshell.Io
import "Logic.js" as Logic

Item {
  id: root

  property var map: ({})
  property int retries: 0

  readonly property int maxRetries: 3

  readonly property string script: Qt.resolvedUrl("launcher-entry-watch.py").toString().replace("file://", "")

  function of(key) { return map[key] || null }

  function apply(update) {
    var parsed = Logic.badgeFrom(update)
    if (!parsed) return
    var next = Object.assign({}, map)
    if (parsed.value === null) delete next[parsed.key]
    else next[parsed.key] = parsed.value
    map = next
  }

  Process {
    id: watch
    running: true
    command: ["python3", root.script]
    stdout: SplitParser {
      onRead: function(line) {
        var update = null
        try { update = JSON.parse(line) } catch (error) { return }
        root.apply(update)
      }
    }
    onExited: {
      if (root.retries >= root.maxRetries) return
      root.retries++
      watchRestart.restart()
    }
  }

  Timer {
    id: watchRestart
    interval: 5000
    onTriggered: watch.running = true
  }
}
