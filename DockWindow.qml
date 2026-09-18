import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

PanelWindow {
  id: win

  required property var modelData
  property var dock

  readonly property int iconSize: dock.config.iconSize
  readonly property int itemPadding: Math.round(iconSize * 0.14)
  readonly property int indicatorSpace: 7
  readonly property int panelPadding: 6
  readonly property int panelHeight: iconSize + itemPadding * 2 + indicatorSpace + panelPadding * 2
  readonly property int edgeGap: 8
  readonly property int overlaySpace: 240
  readonly property int revealStrip: 2
  readonly property int borderWidth: Math.max(1, Style.space(2))

  readonly property bool autohide: dock.config.autohide
  readonly property var hyprMonitor: Hyprland.monitorFor(screen)
  readonly property bool workspaceEmpty: {
    var workspace = hyprMonitor ? hyprMonitor.activeWorkspace : null
    return workspace ? workspace.toplevels.values.length === 0 : false
  }
  readonly property bool wantShown: !autohide || hover.hovered || menuOpen || previewOpen || workspaceEmpty
  property bool shown: !autohide

  property var hoveredItem: null
  property real tooltipCenter: 0
  property bool menuOpen: false
  property var menuEntries: []
  property real menuCenter: 0
  property string previewKey: ""
  property real previewCenter: 0
  readonly property bool previewOpen: previewKey !== ""
  readonly property var previewWindows: previewOpen ? dock.windowsOf(previewKey) : []

  onPreviewWindowsChanged: if (previewOpen && previewWindows.length === 0) previewKey = ""

  function togglePreview(item) {
    menuOpen = false
    if (previewKey === item.appKey) {
      previewKey = ""
      return
    }
    previewCenter = item.mapToItem(content, item.width / 2, 0).x
    previewKey = item.appKey
  }

  function openMenu(item, entries) {
    previewKey = ""
    menuEntries = entries
    menuCenter = item ? item.mapToItem(content, item.width / 2, 0).x : width / 2
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
      tooltipCenter = item.mapToItem(content, item.width / 2, 0).x
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

  screen: modelData
  color: "transparent"
  anchors { left: true; right: true; bottom: true }
  implicitHeight: overlaySpace + panelHeight + edgeGap
  exclusionMode: autohide ? ExclusionMode.Ignore : ExclusionMode.Normal
  exclusiveZone: autohide ? 0 : panelHeight + edgeGap
  WlrLayershell.namespace: "omarchy-dock"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  mask: Region {
    x: win.shown ? panel.x : Math.round((win.width - Math.max(panel.width, 480)) / 2)
    y: win.shown ? win.overlaySpace : win.height - win.revealStrip
    width: win.shown ? panel.width : Math.max(panel.width, 480)
    height: win.shown ? win.height - win.overlaySpace : win.revealStrip

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

      readonly property real restY: win.overlaySpace
      readonly property real hiddenY: win.height + 4

      x: Math.round((parent.width - width) / 2)
      y: win.shown ? restY : hiddenY
      width: row.implicitWidth + win.panelPadding * 2
      height: win.panelHeight
      radius: Style.cornerRadius
      color: Color.bar.background
      border.width: win.borderWidth
      border.color: Color.popups.border

      Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: win.openMenu(null, win.backgroundMenu())
      }

      Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
          model: ScriptModel { values: win.dock.appKeys }
          DockItem {
            required property string modelData
            dock: win.dock
            host: win
            appKey: modelData
          }
        }

      }
    }

    Rectangle {
      id: tooltip

      readonly property bool active: win.hoveredItem !== null && !win.menuOpen && !win.previewOpen && win.shown

      visible: opacity > 0
      opacity: active ? 1 : 0
      x: Math.max(4, Math.min(content.width - width - 4, Math.round(win.tooltipCenter - width / 2)))
      y: panel.restY - height - 8
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
      readonly property int cardWidth: Math.max(120, Math.min(240, Math.floor((content.width - 32) / Math.max(1, count)) - 8))
      readonly property int thumbHeight: Math.round(cardWidth * 0.6)

      visible: win.previewOpen
      x: Math.max(4, Math.min(content.width - width - 4, Math.round(win.previewCenter - width / 2)))
      y: panel.restY - height - 8
      width: previewRow.implicitWidth + 16
      height: previewRow.implicitHeight + 16
      radius: Style.cornerRadius
      color: Color.popups.background
      border.width: win.borderWidth
      border.color: Color.popups.border

      Row {
        id: previewRow
        anchors.centerIn: parent
        spacing: 8

        Repeater {
          model: ScriptModel { values: win.previewWindows }

          Rectangle {
            id: card
            required property var modelData
            readonly property bool minimized: win.dock.isMinimized(modelData)

            width: preview.cardWidth
            height: preview.thumbHeight + cardTitle.implicitHeight + 18
            radius: Style.cornerRadius
            color: cardMouse.containsMouse ? Util.alpha(Color.popups.text, 0.1) : "transparent"
            border.width: card.modelData.activated ? 1 : 0
            border.color: Color.accent

            Item {
              id: thumbBox
              x: 6
              y: 6
              width: parent.width - 12
              height: preview.thumbHeight

              ScreencopyView {
                id: thumb
                anchors.centerIn: parent
                opacity: card.minimized ? 0.45 : 1
                captureSource: card.modelData.wayland
                live: true
                constraintSize: Qt.size(thumbBox.width, thumbBox.height)
              }

              Image {
                anchors.centerIn: parent
                visible: !thumb.hasContent
                width: 48
                height: 48
                sourceSize: Qt.size(48, 48)
                source: win.dock.iconFor(win.dock.appIdOf(card.modelData), win.dock.entryFor(win.dock.appIdOf(card.modelData)))
              }
            }

            Rectangle {
              visible: card.minimized
              x: 10
              y: 10
              width: badge.implicitWidth + 10
              height: badge.implicitHeight + 4
              radius: Style.cornerRadius
              color: Color.popups.background
              border.width: 1
              border.color: Util.alpha(Color.popups.text, 0.4)

              Text {
                id: badge
                anchors.centerIn: parent
                text: win.dock.tr("minimized")
                color: Color.popups.text
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPx(0.8)
              }
            }

            Text {
              id: cardTitle
              x: 6
              y: thumbBox.y + thumbBox.height + 6
              width: parent.width - 12
              text: card.modelData.title || ""
              color: Color.popups.text
              font.family: Style.fontFamily
              font.pixelSize: Style.fontPx(0.9)
              elide: Text.ElideRight
              maximumLineCount: 1
              horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
              id: cardMouse
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton
              onClicked: function(event) {
                if (event.button === Qt.MiddleButton) {
                  win.dock.closeWindow(card.modelData)
                  return
                }
                var host = win
                var target = card.modelData
                host.dock.activateWindow(target)
                host.previewKey = ""
              }
            }

            Rectangle {
              visible: cardMouse.containsMouse || closeMouse.containsMouse
              anchors.top: parent.top
              anchors.right: parent.right
              anchors.margins: 8
              width: 20
              height: 20
              radius: Math.min(10, Style.cornerRadius + 2)
              color: closeMouse.containsMouse ? Color.urgent : Color.popups.background
              border.width: 1
              border.color: Util.alpha(Color.popups.text, 0.4)

              Text {
                anchors.centerIn: parent
                text: "\u00d7"
                color: Color.popups.text
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPx(1.1)
              }

              MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: win.dock.closeWindow(card.modelData)
              }
            }
          }
        }
      }
    }

    Rectangle {
      id: menu

      visible: win.menuOpen
      x: Math.max(4, Math.min(content.width - width - 4, Math.round(win.menuCenter - width / 2)))
      y: panel.restY - height - 8
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
