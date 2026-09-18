import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

PanelWindow {
  id: win

  property var dock
  property bool opened: false
  property int selectedIndex: 0

  readonly property var windows: dock.minimizedWindows.slice().reverse()
  readonly property int borderWidth: Math.max(1, Style.space(2))
  readonly property int cardWidth: 260
  readonly property int cardSpacing: 8
  readonly property int maxColumns: Math.max(1, Math.min(4, Math.floor((width * 0.8) / (cardWidth + cardSpacing))))
  readonly property int columns: Math.max(1, Math.min(windows.length, maxColumns))

  function toggle() {
    if (opened) {
      opened = false
      return
    }
    if (windows.length === 0) return
    selectedIndex = 0
    screen = dock.focusedScreen()
    opened = true
    keys.forceActiveFocus()
  }

  function move(step) {
    if (windows.length === 0) return
    selectedIndex = (selectedIndex + step + windows.length) % windows.length
  }

  function moveRow(step) {
    var next = selectedIndex + step * columns
    if (next >= 0 && next < windows.length) selectedIndex = next
  }

  function restore(toplevel) {
    if (!toplevel) return
    dock.restoreWindow(toplevel)
    opened = false
  }

  onWindowsChanged: {
    if (windows.length === 0) opened = false
    else if (selectedIndex >= windows.length) selectedIndex = windows.length - 1
  }

  visible: opened
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "dockplus-picker"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Rectangle {
    id: keys
    anchors.fill: parent
    color: Color.menu.scrim
    focus: true

    Keys.onEscapePressed: win.opened = false
    Keys.onLeftPressed: win.move(-1)
    Keys.onRightPressed: win.move(1)
    Keys.onUpPressed: win.moveRow(-1)
    Keys.onDownPressed: win.moveRow(1)
    Keys.onTabPressed: win.move(1)
    Keys.onBacktabPressed: win.move(-1)
    Keys.onReturnPressed: win.restore(win.windows[win.selectedIndex])
    Keys.onEnterPressed: win.restore(win.windows[win.selectedIndex])
    Keys.onDeletePressed: if (win.windows[win.selectedIndex]) win.dock.closeWindow(win.windows[win.selectedIndex])

    MouseArea {
      anchors.fill: parent
      onClicked: win.opened = false
    }
  }

  Rectangle {
    id: box
    anchors.centerIn: parent
    width: body.implicitWidth + 32
    height: body.implicitHeight + 32
    radius: Style.cornerRadius
    color: Color.popups.background
    border.width: win.borderWidth
    border.color: Color.popups.border

    MouseArea { anchors.fill: parent }

    Column {
      id: body
      x: 16
      y: 16
      spacing: 12

      Text {
        text: win.dock.tr("pickerTitle")
        color: Color.popups.text
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPx(1.2)
        font.bold: true
      }

      Grid {
        columns: win.columns
        spacing: win.cardSpacing

        Repeater {
          model: ScriptModel { values: win.windows }

          WindowCard {
            required property var modelData
            required property int index
            dock: win.dock
            toplevel: modelData
            cardWidth: win.cardWidth
            selected: win.selectedIndex === index
            showMinimizedState: false
            onHoveredChanged: if (hovered) win.selectedIndex = index
            onPicked: {
              var host = win
              var target = toplevel
              host.restore(target)
            }
            onCloseRequested: win.dock.closeWindow(toplevel)
          }
        }
      }
    }
  }
}
