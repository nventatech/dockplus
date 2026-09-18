import QtQuick
import Quickshell
import qs.Commons

DockSlot {
  id: item

  property string appKey: ""

  readonly property var entry: dock.entryFor(appKey)
  readonly property var windows: dock.windowsOf(appKey)
  readonly property var openWindows: windows.filter(function(window) { return !item.dock.isMinimized(window) })
  readonly property var minimizedWindows: windows.filter(function(window) { return item.dock.isMinimized(window) })
  readonly property bool focused: openWindows.some(function(window) { return window.activated })
  readonly property bool allMinimized: windows.length > 0 && openWindows.length === 0
  readonly property string appId: windows.length > 0 ? dock.appIdOf(windows[0]) : appKey
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
    var actions = dock.actionsFor(appKey)
    actions.forEach(function(action) {
      entries.push({ label: action.name, run: function() { item.dock.runAction(action) } })
    })
    if (actions.length > 0) entries.push({ separator: true })
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

  label: entry ? entry.name : (windows.length > 0 && windows[0].title ? windows[0].title : appId)

  onClicked: function(button) {
    if (button === Qt.RightButton) host.openMenu(item, menuEntries())
    else if (button === Qt.MiddleButton) { if (entry) dock.launch(appKey) }
    else if (windows.length > 1) host.togglePreview(item)
    else dock.activateApp(appKey)
  }

  Image {
    x: item.iconX
    y: item.iconY
    width: item.host.iconSize
    height: item.host.iconSize
    sourceSize: Qt.size(item.host.iconSize, item.host.iconSize)
    source: item.dock.iconFor(item.appId, item.entry)
    asynchronous: true
    smooth: true
    opacity: item.allMinimized ? 0.5 : 1
    scale: item.pressed ? 0.9 : item.hovered ? 1.1 : 1
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
