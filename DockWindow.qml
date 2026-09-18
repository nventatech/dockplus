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
  readonly property int edgeGap: 8
  readonly property int edgeSpace: panelThickness + edgeGap
  readonly property int overlaySpace: vertical ? 380 : 240
  readonly property int popupGap: 8
  readonly property int revealStrip: 2
  readonly property int borderWidth: Math.max(1, Style.space(2))

  readonly property bool autohide: dock.config.autohide
  readonly property var hyprMonitor: Hyprland.monitorFor(screen)
  readonly property bool workspaceEmpty: {
    var workspace = hyprMonitor ? hyprMonitor.activeWorkspace : null
    return workspace ? workspace.toplevels.values.length === 0 : false
  }
  readonly property bool wantShown: !autohide || hover.hovered || menuOpen || previewOpen || workspaceEmpty || dragItem !== null
  property bool shown: !autohide

  property var hoveredItem: null
  property var dragItem: null
  property real tooltipCenter: 0
  property bool menuOpen: false
  property var menuEntries: []
  property real menuCenter: 0
  property string previewKey: ""
  property real previewCenter: 0
  readonly property bool previewOpen: previewKey !== ""
  readonly property bool extrasVisible: dock.config.showAppsButton
  readonly property var previewWindows: previewOpen ? dock.windowsOf(previewKey) : []

  readonly property real stripLength: Math.max(vertical ? panel.height : panel.width, 480)
  readonly property rect inputRect: {
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

  function togglePreview(item) {
    menuOpen = false
    if (previewKey === item.appKey) {
      previewKey = ""
      return
    }
    previewCenter = mainCenter(item)
    previewKey = item.appKey
  }

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
  onAutohideChanged: shown = !autohide || wantShown

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

  Timer { id: showTimer; interval: 120; onTriggered: win.shown = true }
  Timer { id: hideTimer; interval: 450; onTriggered: win.shown = !win.autohide || win.wantShown }

  HyprlandFocusGrab {
    windows: [win]
    active: win.menuOpen || win.previewOpen
    onCleared: {
      win.menuOpen = false
      win.previewKey = ""
    }
  }

  Item {
    id: content
    anchors.fill: parent

    HoverHandler { id: hover }

    Rectangle {
      id: panel

      readonly property real restX: win.position === "left" ? win.edgeGap
        : win.position === "right" ? content.width - win.edgeSpace
        : Math.round((content.width - width) / 2)
      readonly property real restY: win.vertical ? Math.round((content.height - height) / 2) : win.overlaySpace
      readonly property real hiddenX: win.position === "left" ? -(win.panelThickness + 4)
        : win.position === "right" ? content.width + 4
        : restX
      readonly property real hiddenY: win.vertical ? restY : content.height + 4

      x: win.shown ? restX : hiddenX
      y: win.shown ? restY : hiddenY
      width: win.vertical ? win.panelThickness : grid.implicitWidth + win.panelPadding * 2
      height: win.vertical ? grid.implicitHeight + win.panelPadding * 2 : win.panelThickness
      radius: Style.cornerRadius
      color: Color.bar.background
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
          model: ScriptModel { values: win.dock.appKeys }
          DockItem {
            required property string modelData
            dock: win.dock
            host: win
            appKey: modelData
          }
        }

        Item {
          visible: win.extrasVisible && win.dock.appKeys.length > 0
          width: win.vertical ? win.iconSize + win.itemPadding * 2 + win.indicatorSpace : 9
          height: win.vertical ? 9 : win.iconSize + win.itemPadding * 2 + win.indicatorSpace

          Rectangle {
            anchors.centerIn: parent
            width: win.vertical ? Math.round(win.iconSize * 0.6) : 1
            height: win.vertical ? 1 : Math.round(win.iconSize * 0.6)
            color: Util.alpha(Color.bar.text, 0.25)
          }
        }

        DockAction {
          visible: win.dock.config.showAppsButton
          host: win
          label: win.dock.tr("applications")
          glyph: appsGlyph
          onActivated: win.dock.openAppsMenu()
          menuBuilder: win.backgroundMenu
        }
      }

      Component {
        id: appsGlyph

        Item {
          Grid {
            anchors.centerIn: parent
            columns: 3
            spacing: Math.round(win.iconSize * 0.09)

            Repeater {
              model: 9
              Rectangle {
                width: Math.round(win.iconSize * 0.17)
                height: width
                radius: Math.round(width * 0.3)
                color: Color.bar.text
              }
            }
          }
        }
      }

      Rectangle {
        readonly property var source: win.dragItem
        readonly property bool active: source !== null && source.dropIndex >= 0 && source.dropIndex !== source.pinnedIndex
        readonly property int slot: !active ? 0 : source.dropIndex > source.pinnedIndex ? source.dropIndex + 1 : source.dropIndex
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
            height: menuLabel.implicitHeight + 14
            radius: Style.cornerRadius
            color: menuMouse.containsMouse ? Util.alpha(Color.popups.text, 0.1) : "transparent"

            Text {
              id: menuLabel
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
              onClicked: win.runMenuEntry(menuRow.entry)
            }
          }
        }
      }
    }
  }
}
