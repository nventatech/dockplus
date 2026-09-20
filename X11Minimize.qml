import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  signal requested(int pid, string title)

  readonly property string script: Qt.resolvedUrl("x11-minimize-watch.py").toString().replace("file://", "")

  Process {
    id: watch
    running: true
    command: ["python3", root.script]
    stdout: SplitParser {
      onRead: function(line) {
        var request = null
        try { request = JSON.parse(line) } catch (error) { return }
        root.requested(Number(request.pid) || 0, String(request.title || ""))
      }
    }
    onExited: watchRestart.restart()
  }

  Timer {
    id: watchRestart
    interval: 5000
    onTriggered: watch.running = true
  }
}
