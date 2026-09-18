import QtQuick
import Quickshell
import qs.Commons

DockSlot {
  id: item

  property string appKey: ""

  readonly property var entry: dock.entryFor(appKey)
  readonly property var windows: dock.windowsOf(appKey, host.scope)
  readonly property var openWindows: windows.filter(function(window) { return !item.dock.isMinimized(window) })
  readonly property var minimizedWindows: windows.filter(function(window) { return item.dock.isMinimized(window) })
  readonly property bool focused: openWindows.some(function(window) { return window.activated })
  readonly property bool allMinimized: windows.length > 0 && openWindows.length === 0
  readonly property bool launching: dock.isLaunching(appKey)
  readonly property bool urgent: dock.isUrgent(appKey)
  property real bounce: 0
  property real wiggle: 0
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
    if (entry) entries.push({ label: dock.tr("newWindow"), run: function() { item.dock.newWindow(item.appKey) } })
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

  function leftClick() {
    var mode = dock.config.clickAction
    if (!(mode === "smart" && windows.length > 1)) host.dismissHoverPreview()
    if (mode === "launch" && entry) dock.newWindow(appKey)
    else if (mode === "cycle") dock.cycleClick(appKey, host.scope)
    else if (windows.length > 1) host.togglePreview(item)
    else dock.activateApp(appKey, host.scope)
  }

  label: entry ? entry.name : (windows.length > 0 && windows[0].title ? windows[0].title : appId)

  onDragHeld: {
    var target = openWindows.length > 0 ? openWindows[0] : windows[0]
    if (!target) {
      var elsewhere = dock.windowsOf(appKey)
      target = elsewhere.length > 0 ? elsewhere[0] : null
    }
    if (target) dock.activateWindow(target)
  }

  activatesOnDrag: true

  onScrolled: function(step) { dock.cycleWindows(appKey, step, host.scope) }

  onClicked: function(button) {
    if (button === Qt.RightButton) host.openMenu(item, menuEntries())
    else if (button === Qt.MiddleButton) { if (entry) dock.newWindow(appKey) }
    else leftClick()
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
    rotation: item.wiggle
    scale: item.iconScale
    Behavior on opacity { NumberAnimation { duration: item.host.duration(140) } }
    Behavior on scale { NumberAnimation { duration: item.host.duration(110); easing.type: Easing.OutCubic } }

    transform: Translate {
      x: item.host.position === "left" ? item.bounce : item.host.position === "right" ? -item.bounce : 0
      y: item.host.vertical ? 0 : -item.bounce
    }
  }

  SequentialAnimation {
    running: item.launching && item.dock.config.animations && item.dock.config.launchBounce
    loops: Animation.Infinite
    onRunningChanged: if (!running) item.bounce = 0
    NumberAnimation { target: item; property: "bounce"; to: item.host.iconSize * 0.25; duration: item.host.duration(260); easing.type: Easing.OutQuad }
    NumberAnimation { target: item; property: "bounce"; to: 0; duration: item.host.duration(260); easing.type: Easing.InQuad }
    PauseAnimation { duration: item.host.duration(180) }
  }

  SequentialAnimation {
    running: item.urgent && item.dock.config.animations && item.dock.config.urgentWiggle
    loops: Animation.Infinite
    onRunningChanged: if (!running) item.wiggle = 0
    NumberAnimation { target: item; property: "wiggle"; to: -12; duration: item.host.duration(70) }
    NumberAnimation { target: item; property: "wiggle"; to: 12; duration: item.host.duration(120) }
    NumberAnimation { target: item; property: "wiggle"; to: -8; duration: item.host.duration(110) }
    NumberAnimation { target: item; property: "wiggle"; to: 8; duration: item.host.duration(100) }
    NumberAnimation { target: item; property: "wiggle"; to: 0; duration: item.host.duration(80) }
    PauseAnimation { duration: 1400 }
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
        readonly property string style: item.dock.config.indicatorStyle
        readonly property int along: style === "dots" ? 4
          : style === "dashes" ? Math.round(item.host.iconSize * 0.2)
          : style === "segments" ? Math.floor((item.host.iconSize * 0.6 - 3 * (item.indicators.length - 1)) / item.indicators.length)
          : modelData === "focused" ? Math.round(item.host.iconSize * 0.34) : modelData === "minimized" ? 7 : 4
        readonly property int across: style === "dashes" || style === "segments" ? 3
          : style === "default" && modelData === "minimized" ? 2 : 4
        width: item.host.vertical ? across : along
        height: item.host.vertical ? along : across
        radius: across / 2
        color: modelData === "focused" ? Color.accent
          : Util.alpha(Color.bar.text, modelData === "minimized" ? 0.45 : 0.7)
      }
    }
  }
}
