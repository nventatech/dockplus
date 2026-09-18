import QtQuick
import Quickshell
import qs.Commons

Item {
  id: item

  property var dock
  property var host
  property string appKey: ""

  readonly property var entry: dock.entryFor(appKey)
  readonly property var windows: dock.windowsOf(appKey)
  readonly property var openWindows: windows.filter(function(window) { return !item.dock.isMinimized(window) })
  readonly property var minimizedWindows: windows.filter(function(window) { return item.dock.isMinimized(window) })
  readonly property bool focused: openWindows.some(function(window) { return window.activated })
  readonly property bool allMinimized: windows.length > 0 && openWindows.length === 0
  readonly property string appId: windows.length > 0 ? dock.appIdOf(windows[0]) : appKey
  readonly property string label: entry ? entry.name : (windows.length > 0 && windows[0].title ? windows[0].title : appId)
  readonly property var indicators: {
    var states = []
    for (var i = 0; i < windows.length && states.length < 3; i++) {
      if (dock.isMinimized(windows[i])) states.push("minimized")
      else states.push(windows[i].activated ? "focused" : "open")
    }
    return states
  }

  function menuEntries() {
    var entries = []
    var open = openWindows.slice()
    var minimized = minimizedWindows.slice()
    var all = windows.slice()
    if (entry) entries.push({ label: dock.tr("newWindow"), run: function() { item.dock.launch(item.appKey) } })
    if (open.length > 0) entries.push({ label: dock.tr("minimize"), run: function() {
      var target = open.find(function(window) { return window.activated }) || open[0]
      item.dock.minimizeWindow(target)
    } })
    if (minimized.length > 0) entries.push({ label: dock.tr("restore"), run: function() {
      item.dock.restoreWindow(minimized[minimized.length - 1])
    } })
    if (dock.config.isPinned(appKey))
      entries.push({ label: dock.tr("unpin"), run: function() { item.dock.config.unpin(item.appKey) } })
    else if (entry)
      entries.push({ label: dock.tr("pin"), run: function() { item.dock.config.pin(item.appKey) } })
    if (all.length > 0) entries.push({
      label: dock.tr(all.length > 1 ? "closeAll" : "close"),
      run: function() { all.forEach(function(window) { item.dock.closeWindow(window) }) }
    })
    entries.push({ label: dock.tr("settings"), run: function() { item.dock.openSettings() } })
    return entries
  }

  width: host.iconSize + host.itemPadding * 2
  height: host.iconSize + host.itemPadding * 2 + host.indicatorSpace

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: Util.alpha(Color.bar.text, mouse.pressed ? 0.16 : mouse.containsMouse ? 0.09 : 0)
    Behavior on color { ColorAnimation { duration: 100 } }
  }

  Image {
    x: item.host.itemPadding
    y: item.host.itemPadding
    width: item.host.iconSize
    height: item.host.iconSize
    sourceSize: Qt.size(item.host.iconSize, item.host.iconSize)
    source: item.dock.iconFor(item.appId, item.entry)
    asynchronous: true
    smooth: true
    opacity: item.allMinimized ? 0.5 : 1
    scale: mouse.pressed ? 0.9 : mouse.containsMouse ? 1.1 : 1
    Behavior on opacity { NumberAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 1
    height: 4
    spacing: 3

    Repeater {
      model: item.indicators
      Rectangle {
        required property string modelData
        anchors.verticalCenter: parent.verticalCenter
        width: modelData === "focused" ? Math.round(item.host.iconSize * 0.34) : modelData === "minimized" ? 7 : 4
        height: modelData === "minimized" ? 2 : 4
        radius: height / 2
        color: modelData === "focused" ? Color.accent
          : Util.alpha(Color.bar.text, modelData === "minimized" ? 0.45 : 0.7)
      }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onContainsMouseChanged: item.host.setHovered(item, containsMouse)
    onClicked: function(event) {
      if (event.button === Qt.RightButton) item.host.openMenu(item, item.menuEntries())
      else if (event.button === Qt.MiddleButton) { if (item.entry) item.dock.launch(item.appKey) }
      else if (item.windows.length > 1) item.host.togglePreview(item)
      else item.dock.activateApp(item.appKey)
    }
  }

  Component.onDestruction: host.setHovered(item, false)
}
