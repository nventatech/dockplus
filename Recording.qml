import QtQuick
import Quickshell.Io

Item {
  id: root

  property bool enabled: true
  property bool active: false

  readonly property string markerPath: "/tmp/omarchy-screenrecord-filename"

  onEnabledChanged: if (!enabled) active = false

  FileView {
    id: marker
    path: root.markerPath
    printErrors: false
    onLoaded: root.active = true
    onLoadFailed: root.active = false
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.enabled
    triggeredOnStart: true
    onTriggered: marker.reload()
  }
}
