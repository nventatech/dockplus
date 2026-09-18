import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

PanelWindow {
  id: win

  required property var modelData
  property var dock

  readonly property string position: modelData.position
  readonly property bool vertical: position !== "bottom"

  readonly property int iconSize: dock.config.iconSize
  readonly property int itemPadding: Math.round(iconSize * 0.14)
  readonly property int indicatorSpace: 7
  readonly property int panelPadding: 6
  readonly property int itemSpacing: 2
  readonly property int slotSize: iconSize + itemPadding * 2 + itemSpacing
  readonly property int panelThickness: iconSize + itemPadding * 2 + indicatorSpace + panelPadding * 2
  readonly property bool panelMode: dock.config.panelMode
  readonly property int edgeGap: panelMode ? 0 : 8
  readonly property int edgeSpace: panelThickness + edgeGap
  readonly property int overlaySpace: vertical ? 380 : 520
  readonly property int popupGap: 8
  readonly property int revealStrip: 2
  readonly property int borderWidth: Math.max(1, Style.space(2))

  readonly property bool autohide: dock.config.autohide
  readonly property var hyprMonitor: Hyprland.monitorFor(screen)
  readonly property bool workspaceEmpty: {
    var workspace = hyprMonitor ? hyprMonitor.activeWorkspace : null
    return workspace ? workspace.toplevels.values.length === 0 : false
  }
  readonly property bool fullscreenActive: hyprMonitor ? dock.fullscreenOn(hyprMonitor.name) : false
  readonly property bool wantShown: !fullscreenActive
    && (!autohide || hover.hovered || menuOpen || previewOpen || workspaceEmpty || dragItem !== null || urgentReveal || numbersVisible || fileDragActive)
  property bool shown: !autohide
  property bool urgentReveal: false
  property bool numbersVisible: false
  property bool fileDragActive: false

  property var hoveredItem: null
  property var dragItem: null
  property real tooltipCenter: 0
  property bool menuOpen: false
  property var menuEntries: []
  property real menuCenter: 0
  property string previewKey: ""
  property bool previewByHover: false
  property var hoverCandidate: null
  property real previewCenter: 0
  readonly property bool previewOpen: previewKey !== ""
  readonly property var scope: dock.scopeFor(hyprMonitor)
  readonly property var entries: dock.entriesFor(scope)
  readonly property var previewWindows: previewOpen ? dock.windowsOf(previewKey, scope) : []

  readonly property real stripLength: Math.max(vertical ? panel.height : panel.width, 480)
  readonly property rect inputRect: {
    if (fullscreenActive) return Qt.rect(0, 0, 0, 0)
    if (shown) {
      if (position === "left") return Qt.rect(0, panel.y, edgeSpace, panel.height)
      if (position === "right") return Qt.rect(width - edgeSpace, panel.y, edgeSpace, panel.height)
      return Qt.rect(panel.x, overlaySpace, panel.width, height - overlaySpace)
    }
    if (position === "left") return Qt.rect(0, Math.round((height - stripLength) / 2), revealStrip, stripLength)
    if (position === "right") return Qt.rect(width - revealStrip, Math.round((height - stripLength) / 2), revealStrip, stripLength)
    return Qt.rect(Math.round((width - stripLength) / 2), height - revealStrip, stripLength, revealStrip)
  }

  onPreviewWindowsChanged: if (previewOpen && previewWindows.length === 0) previewKey = ""

  function mainCenter(item) {
    var point = item.mapToItem(content, item.width / 2, item.height / 2)
    return vertical ? point.y : point.x
  }

  function popupX(size, center) {
    if (position === "left") return panel.restX + panelThickness + popupGap
    if (position === "right") return panel.restX - size - popupGap
    return Math.max(4, Math.min(content.width - size - 4, Math.round(center - size / 2)))
  }

  function popupY(size, center) {
    if (!vertical) return panel.restY - size - popupGap
    return Math.max(4, Math.min(content.height - size - 4, Math.round(center - size / 2)))
  }

  function fileDragEnter() {
    fileDragTimer.stop()
    fileDragActive = true
  }

  function fileDragLeave() { fileDragTimer.restart() }

  function fileDragDone() {
    fileDragTimer.stop()
    fileDragActive = false
  }

  function activateEntry(index) {
    if (index < 0 || index >= entries.length) return
    if (!fullscreenActive) {
      numbersVisible = true
      numbersTimer.restart()
    }
    dock.activateEntry(entries[index], scope)
  }

  function togglePreview(item) {
    menuOpen = false
    previewCloseTimer.stop()
    if (previewKey === item.appKey) {
      if (previewByHover) previewByHover = false
      else previewKey = ""
      return
    }
    previewCenter = mainCenter(item)
    previewKey = item.appKey
    previewByHover = false
  }

  function openHoverPreview(item) {
    if (menuOpen || previewKey === item.appKey) return
    previewCenter = mainCenter(item)
    previewKey = item.appKey
    previewByHover = true
  }

  function dismissHoverPreview() {
    previewOpenTimer.stop()
    previewCloseTimer.stop()
    if (previewByHover) previewKey = ""
  }

  function hoverTargetsPreview(item) {
    return !!item && item.windows !== undefined && item.windows.length > 0
  }

  onHoveredItemChanged: {
    if (!dock.config.previewOnHover || dragItem !== null) return
    if (hoverTargetsPreview(hoveredItem)) {
      hoverCandidate = hoveredItem
      previewCloseTimer.stop()
      previewOpenTimer.restart()
    } else {
      previewOpenTimer.stop()
      if (previewByHover) previewCloseTimer.restart()
    }
  }

  onPreviewKeyChanged: if (previewKey === "") previewByHover = false

  function openMenu(item, entries) {
    previewKey = ""
    menuEntries = entries
    menuCenter = item ? mainCenter(item) : (vertical ? height : width) / 2
    menuOpen = true
  }

  function runMenuEntry(entry) {
    menuOpen = false
    if (entry && typeof entry.run === "function") entry.run()
  }

  function driveMenu(drive) {
    var drives = dock.drives
    var entries = [{ label: dock.tr("open"), run: function() { drives.open(drive) } }]
    if (drive.mounted) entries.push({ label: dock.tr("unmount"), run: function() { drives.unmount(drive) } })
    entries.push({ label: dock.tr("safelyRemove"), run: function() { drives.eject(drive) } })
    return entries
  }

  function trashMenu(anchor) {
    var trash = dock.trash
    var entries = [{ label: dock.tr("open"), run: function() { trash.open() } }]
    if (trash.count > 0) entries.push({
      label: dock.tr("emptyTrash") + " (" + trash.count + ")",
      run: function() { win.openMenu(anchor, win.confirmEmptyTrashMenu()) }
    })
    return entries
  }

  function confirmEmptyTrashMenu() {
    var trash = dock.trash
    return [
      { label: dock.tr("confirmEmptyTrash").replace("%1", trash.count), run: function() { trash.empty() } },
      { label: dock.tr("cancel"), run: function() {} }
    ]
  }

  function backgroundMenu() {
    return [{ label: dock.tr("settings"), run: function() { dock.openSettings() } }]
  }

  function setHovered(item, hovered) {
    if (hovered) {
      hoveredItem = item
      tooltipCenter = mainCenter(item)
    } else if (hoveredItem === item) {
      hoveredItem = null
    }
  }

  onWantShownChanged: {
    if (wantShown) {
      hideTimer.stop()
      showTimer.restart()
    } else {
      showTimer.stop()
      hideTimer.restart()
    }
  }
  onAutohideChanged: shown = wantShown
  onFullscreenActiveChanged: {
    if (!fullscreenActive) return
    showTimer.stop()
    menuOpen = false
    previewKey = ""
    shown = false
  }

  screen: modelData.screen
  color: "transparent"
  anchors {
    left: win.position !== "right"
    right: win.position !== "left"
    top: win.vertical
    bottom: true
  }
  implicitWidth: overlaySpace + edgeSpace
  implicitHeight: overlaySpace + edgeSpace
  exclusionMode: autohide ? ExclusionMode.Ignore : ExclusionMode.Normal
  exclusiveZone: autohide ? 0 : edgeSpace
  WlrLayershell.namespace: "omarchy-dock"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  mask: Region {
    x: win.inputRect.x
    y: win.inputRect.y
    width: win.inputRect.width
    height: win.inputRect.height

    Region {
      x: menu.x
      y: menu.y
      width: win.menuOpen ? menu.width : 0
      height: win.menuOpen ? menu.height : 0
    }

    Region {
      x: preview.x
      y: preview.y
      width: win.previewOpen ? preview.width : 0
      height: win.previewOpen ? preview.height : 0
    }
  }

  Connections {
    target: win.dock
    function onUrgentSerialChanged() {
      if (win.fullscreenActive) return
      win.urgentReveal = true
      urgentTimer.restart()
    }
  }

  Timer {
    id: previewOpenTimer
    interval: 500
    onTriggered: if (win.hoverCandidate && win.hoveredItem === win.hoverCandidate) win.openHoverPreview(win.hoverCandidate)
  }

  Timer {
    id: previewCloseTimer
    interval: 400
    onTriggered: {
      if (!win.previewByHover || previewHover.hovered) return
      if (win.hoveredItem && win.hoveredItem.appKey === win.previewKey) return
      win.previewKey = ""
    }
  }

  Timer { id: fileDragTimer; interval: 400; onTriggered: win.fileDragActive = false }
  Timer { id: numbersTimer; interval: 1500; onTriggered: win.numbersVisible = false }
  Timer { id: urgentTimer; interval: 3000; onTriggered: win.urgentReveal = false }
  Timer { id: showTimer; interval: 120; onTriggered: win.shown = true }
  Timer { id: hideTimer; interval: 450; onTriggered: win.shown = win.wantShown }

  HyprlandFocusGrab {
    windows: [win]
    active: win.menuOpen || (win.previewOpen && !win.previewByHover)
    onCleared: {
      win.menuOpen = false
      win.previewKey = ""
    }
  }

  Item {
    id: content
    anchors.fill: parent

    HoverHandler { id: hover }

    DropArea {
      anchors.fill: parent
      keys: ["text/uri-list"]
      onEntered: win.fileDragEnter()
      onExited: win.fileDragLeave()
      onDropped: win.fileDragDone()
    }

    Rectangle {
      id: panel

      readonly property real restX: win.panelMode && !win.vertical ? 0
        : win.position === "left" ? win.edgeGap
        : win.position === "right" ? content.width - win.edgeSpace
        : Math.round((content.width - width) / 2)
      readonly property real restY: win.panelMode && win.vertical ? 0
        : win.vertical ? Math.round((content.height - height) / 2) : win.overlaySpace
      readonly property real hiddenX: win.position === "left" ? -(win.panelThickness + 4)
        : win.position === "right" ? content.width + 4
        : restX
      readonly property real hiddenY: win.vertical ? restY : content.height + 4

      x: win.shown ? restX : hiddenX
      y: win.shown ? restY : hiddenY
      width: win.vertical ? win.panelThickness : win.panelMode ? content.width : grid.implicitWidth + win.panelPadding * 2
      height: !win.vertical ? win.panelThickness : win.panelMode ? content.height : grid.implicitHeight + win.panelPadding * 2
      radius: win.panelMode ? 0 : Style.cornerRadius
      color: Util.alpha(Color.bar.background, win.dock.config.backgroundOpacity / 100)
      border.width: win.borderWidth
      border.color: Color.popups.border

      Behavior on x { enabled: win.vertical; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on y { enabled: !win.vertical; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on width { enabled: !win.vertical; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
      Behavior on height { enabled: win.vertical; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: win.openMenu(null, win.backgroundMenu())
      }

      Grid {
        id: grid
        anchors.centerIn: parent
        columns: win.vertical ? 1 : -1
        rows: win.vertical ? -1 : 1
        spacing: win.itemSpacing

        Repeater {
          model: ScriptModel {
            objectProp: "key"
            values: win.entries
          }

          DockEntry {
            dock: win.dock
            host: win
          }
        }
      }

      Rectangle {
        readonly property var source: win.dragItem
        readonly property bool active: source !== null && source.dropIndex >= 0 && source.dropIndex !== source.renderedIndex
        readonly property int slot: !active ? 0 : source.dropIndex > source.renderedIndex ? source.dropIndex + 1 : source.dropIndex
        readonly property real along: slot * win.slotSize - Math.round(win.itemSpacing / 2) - 1
        readonly property real across: win.itemPadding + (win.position === "left" ? win.indicatorSpace : 0)

        visible: active
        x: grid.x + (win.vertical ? across : along)
        y: grid.y + (win.vertical ? along : across)
        width: win.vertical ? win.iconSize : 2
        height: win.vertical ? 2 : win.iconSize
        radius: 1
        color: Color.accent
      }
    }

    Rectangle {
      id: tooltip

      readonly property bool active: win.hoveredItem !== null && !win.menuOpen && !win.previewOpen && win.shown && win.dragItem === null

      visible: opacity > 0
      opacity: active ? 1 : 0
      x: win.popupX(width, win.tooltipCenter)
      y: win.popupY(height, win.tooltipCenter)
      width: Math.min(360, tooltipText.implicitWidth + 20)
      height: tooltipText.implicitHeight + 10
      radius: Style.cornerRadius
      color: Color.tooltip.background
      border.width: 1
      border.color: Util.alpha(Color.tooltip.border, 0.4)

      Behavior on opacity { NumberAnimation { duration: 100 } }

      Text {
        id: tooltipText
        anchors.centerIn: parent
        width: Math.min(implicitWidth, 340)
        text: win.hoveredItem ? win.hoveredItem.label : ""
        color: Color.tooltip.text
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPx(1)
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }

    Rectangle {
      id: preview

      HoverHandler {
        id: previewHover
        onHoveredChanged: {
          if (hovered) previewCloseTimer.stop()
          else if (win.previewByHover) previewCloseTimer.restart()
        }
      }

      readonly property int count: win.previewWindows.length
      readonly property int cardWidth: win.vertical
        ? Math.max(120, Math.min(220, Math.floor(((content.height - 32) / Math.max(1, count) - 48) / 0.6)))
        : Math.max(120, Math.min(240, Math.floor((content.width - 32) / Math.max(1, count)) - 8))

      visible: win.previewOpen
      x: win.popupX(width, win.previewCenter)
      y: win.popupY(height, win.previewCenter)
      width: previewGrid.implicitWidth + 16
      height: previewGrid.implicitHeight + 16
      radius: Style.cornerRadius
      color: Color.popups.background
      border.width: win.borderWidth
      border.color: Color.popups.border

      Grid {
        id: previewGrid
        anchors.centerIn: parent
        columns: win.vertical ? 1 : Math.max(1, preview.count)
        spacing: 8

        Repeater {
          model: ScriptModel { values: win.previewWindows }

          WindowCard {
            required property var modelData
            dock: win.dock
            toplevel: modelData
            cardWidth: preview.cardWidth
            onPicked: {
              var host = win
              var target = toplevel
              host.dock.activateWindow(target)
              host.previewKey = ""
            }
            onCloseRequested: win.dock.closeWindow(toplevel)
          }
        }
      }
    }

    Rectangle {
      id: menu

      visible: win.menuOpen
      x: win.popupX(width, win.menuCenter)
      y: win.popupY(height, win.menuCenter)
      width: menuColumn.implicitWidth + 8
      height: menuColumn.implicitHeight + 8
      radius: Style.cornerRadius
      color: Color.popups.background
      border.width: win.borderWidth
      border.color: Color.popups.border

      Column {
        id: menuColumn
        anchors.centerIn: parent

        Repeater {
          model: win.menuEntries.length

          Rectangle {
            id: menuRow
            required property int index
            readonly property var entry: win.menuEntries[index] || ({})

            width: 230
            height: entry.separator ? 9 : menuLabel.implicitHeight + 14
            radius: Style.cornerRadius
            color: menuMouse.containsMouse && !entry.separator ? Util.alpha(Color.popups.text, 0.1) : "transparent"

            Rectangle {
              visible: menuRow.entry.separator === true
              anchors.verticalCenter: parent.verticalCenter
              x: 10
              width: parent.width - 20
              height: 1
              color: Util.alpha(Color.popups.text, 0.15)
            }

            Text {
              id: menuLabel
              visible: menuRow.entry.separator !== true
              anchors.verticalCenter: parent.verticalCenter
              x: 14
              width: parent.width - 28
              elide: Text.ElideRight
              text: menuRow.entry.label || ""
              color: Color.popups.text
              font.family: Style.fontFamily
              font.pixelSize: Style.fontPx(1)
            }

            MouseArea {
              id: menuMouse
              anchors.fill: parent
              hoverEnabled: true
              enabled: menuRow.entry.separator !== true
              onClicked: win.runMenuEntry(menuRow.entry)
            }
          }
        }
      }
    }
  }
}
