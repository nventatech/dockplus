import QtQuick
import Quickshell
import qs.Commons

Item {
  id: item

  property var dock
  property var host
  property string appKey: ""

  property int dropIndex: -1
  property bool wasDragged: false

  readonly property bool pinned: dock.config.isPinned(appKey)
  readonly property int pinnedIndex: dock.config.pinned.indexOf(appKey)
  readonly property bool dragging: mouse.drag.active
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

  function updateDrop() {
    var center = pinnedIndex * host.slotSize + host.slotSize / 2 + (host.vertical ? body.y : body.x)
    dropIndex = Math.max(0, Math.min(dock.config.pinned.length - 1, Math.floor(center / host.slotSize)))
  }

  onDraggingChanged: {
    if (dragging) {
      wasDragged = true
      host.dragItem = item
      updateDrop()
      return
    }
    var config = dock.config
    var key = appKey
    var target = dropIndex
    body.x = 0
    body.y = 0
    dropIndex = -1
    host.dragItem = null
    if (target >= 0) config.movePinned(key, target)
  }

  width: host.iconSize + host.itemPadding * 2 + (host.vertical ? host.indicatorSpace : 0)
  height: host.iconSize + host.itemPadding * 2 + (host.vertical ? 0 : host.indicatorSpace)
  z: dragging ? 10 : 0

  Item {
    id: body
    width: parent.width
    height: parent.height
    scale: item.dragging ? 1.06 : 1
    onXChanged: if (item.dragging) item.updateDrop()
    onYChanged: if (item.dragging) item.updateDrop()

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: Util.alpha(Color.bar.text, mouse.pressed ? 0.16 : mouse.containsMouse ? 0.09 : 0)
      Behavior on color { ColorAnimation { duration: 100 } }
    }

    Image {
      x: item.host.itemPadding + (item.host.position === "left" ? item.host.indicatorSpace : 0)
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

    Grid {
      x: !item.host.vertical ? Math.round((parent.width - width) / 2)
        : item.host.position === "left" ? 1 : parent.width - width - 1
      y: item.host.vertical ? Math.round((parent.height - height) / 2) : parent.height - height - 1
      columns: item.host.vertical ? 1 : 3
      spacing: 3
      horizontalItemAlignment: Grid.AlignHCenter
      verticalItemAlignment: Grid.AlignVCenter

      Repeater {
        model: item.indicators
        Rectangle {
          required property string modelData
          readonly property int along: modelData === "focused" ? Math.round(item.host.iconSize * 0.34) : modelData === "minimized" ? 7 : 4
          readonly property int across: modelData === "minimized" ? 2 : 4
          width: item.host.vertical ? across : along
          height: item.host.vertical ? along : across
          radius: across / 2
          color: modelData === "focused" ? Color.accent
            : Util.alpha(Color.bar.text, modelData === "minimized" ? 0.45 : 0.7)
        }
      }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    drag.target: item.pinned ? body : null
    drag.axis: item.host.vertical ? Drag.YAxis : Drag.XAxis
    drag.minimumX: -item.pinnedIndex * item.host.slotSize
    drag.maximumX: (item.dock.config.pinned.length - 1 - item.pinnedIndex) * item.host.slotSize
    drag.minimumY: drag.minimumX
    drag.maximumY: drag.maximumX
    onPressed: item.wasDragged = false
    onContainsMouseChanged: item.host.setHovered(item, containsMouse)
    onClicked: function(event) {
      if (item.wasDragged) return
      if (event.button === Qt.RightButton) item.host.openMenu(item, item.menuEntries())
      else if (event.button === Qt.MiddleButton) { if (item.entry) item.dock.launch(item.appKey) }
      else if (item.windows.length > 1) item.host.togglePreview(item)
      else item.dock.activateApp(item.appKey)
    }
  }

  Component.onDestruction: host.setHovered(item, false)
}
