import QtQuick
import Quickshell.Io

Item {
  id: root

  property bool enabled: true
  property bool active: false

  readonly property string markerPath: "/tmp/omarchy-screenrecord-filename"

  onEnabledChanged: if (!enabled) active = false

  Process {
    id: watch
    running: root.enabled
    command: ["sh", "-c",
      'previous=\n'
      + 'while :; do\n'
      + '  if [ -e "$1" ]; then current=1; else current=0; fi\n'
      + '  if [ "$current" != "$previous" ]; then printf "%s\\n" "$current"; previous=$current; fi\n'
      + '  sleep 1\n'
      + 'done',
      "sh", root.markerPath]
    stdout: SplitParser {
      onRead: function(line) { root.active = String(line).trim() === "1" }
    }
    onExited: if (root.enabled) watchRestart.restart()
  }

  Timer {
    id: watchRestart
    interval: 5000
    onTriggered: watch.running = root.enabled
  }
}
