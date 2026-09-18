import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

PanelWindow {
  id: win

  property var dock
  property bool opened: false

  readonly property var config: dock.config
  readonly property int borderWidth: Math.max(1, Style.space(2))
  readonly property int columnWidth: 380
  readonly property var positionChoices: [
    { value: "bottom", label: dock.tr("positionBottom") },
    { value: "left", label: dock.tr("positionLeft") },
    { value: "right", label: dock.tr("positionRight") }
  ]
  readonly property var clickChoices: [
    { value: "smart", label: dock.tr("clickSmart") },
    { value: "cycle", label: dock.tr("clickCycle") },
    { value: "launch", label: dock.tr("clickLaunch") }
  ]
  readonly property var indicatorChoices: [
    { value: "default", label: dock.tr("indicatorDefault") },
    { value: "dots", label: dock.tr("indicatorDots") },
    { value: "dashes", label: dock.tr("indicatorDashes") },
    { value: "segments", label: dock.tr("indicatorSegments") }
  ]
  readonly property var monitorChoices: {
    var choices = [{ value: "", label: dock.tr("allMonitors") }]
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++) choices.push({ value: screens[i].name, label: screens[i].name })
    return choices
  }

  onOpenedChanged: if (opened) screen = dock.focusedScreen()

  visible: opened
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "omarchy-dock-settings"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Rectangle {
    anchors.fill: parent
    color: Color.menu.scrim
    focus: true
    Keys.onEscapePressed: win.opened = false

    MouseArea {
      anchors.fill: parent
      onClicked: win.opened = false
    }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: body.implicitWidth + 48
    height: body.implicitHeight + 48
    radius: Style.cornerRadius
    color: Color.popups.background
    border.width: win.borderWidth
    border.color: Color.popups.border

    MouseArea { anchors.fill: parent }

    Column {
      id: body
      x: 24
      y: 24
      spacing: 22

      Text {
        text: win.dock.tr("settingsTitle")
        color: Color.popups.text
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPx(1.4)
        font.bold: true
      }

      Grid {
        columns: win.width >= win.columnWidth * 2 + 140 ? 2 : 1
        columnSpacing: 40
        rowSpacing: 22

        Column {
          width: win.columnWidth
          spacing: 22

          Text {
            text: win.dock.tr("appearance")
            color: Util.alpha(Color.popups.text, 0.6)
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPx(0.9)
            font.bold: true
          }

          SliderRow {
            width: parent.width
            label: win.dock.tr("iconSize")
            valueText: win.config.iconSize + " px"
            ratio: (win.config.iconSize - win.config.minIconSize) / (win.config.maxIconSize - win.config.minIconSize)
            onMoved: function(ratio) {
              var value = win.config.minIconSize + ratio * (win.config.maxIconSize - win.config.minIconSize)
              win.config.setIconSize(Math.round(value / 4) * 4)
            }
          }

          SliderRow {
            width: parent.width
            label: win.dock.tr("backgroundOpacity")
            valueText: win.config.backgroundOpacity + "%"
            ratio: (win.config.backgroundOpacity - win.config.minOpacity) / (100 - win.config.minOpacity)
            onMoved: function(ratio) {
              var value = win.config.minOpacity + ratio * (100 - win.config.minOpacity)
              win.config.setBackgroundOpacity(Math.round(value / 5) * 5)
            }
          }

          ChoiceRow {
            width: parent.width
            label: win.dock.tr("position")
            options: win.positionChoices
            current: win.config.position
            onChosen: function(value) { win.config.setPosition(value) }
          }

          ChoiceRow {
            width: parent.width
            label: win.dock.tr("monitor")
            options: win.monitorChoices
            current: win.config.monitor
            onChosen: function(value) { win.config.setMonitor(value) }
          }

          ChoiceRow {
            width: parent.width
            label: win.dock.tr("indicatorStyle")
            options: win.indicatorChoices
            current: win.config.indicatorStyle
            onChosen: function(value) { win.config.setIndicatorStyle(value) }
          }

          ToggleRow {
            width: parent.width
            label: win.dock.tr("panelMode")
            hint: win.dock.tr("panelModeHint")
            checked: win.config.panelMode
            onToggled: function(value) { win.config.setPanelMode(value) }
          }
        }

        Column {
          width: win.columnWidth
          spacing: 22

          Text {
            text: win.dock.tr("behavior")
            color: Util.alpha(Color.popups.text, 0.6)
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPx(0.9)
            font.bold: true
          }

          ToggleRow {
            width: parent.width
            label: win.dock.tr("autohide")
            hint: win.dock.tr("autohideHint")
            checked: win.config.autohide
            onToggled: function(value) { win.config.setAutohide(value) }
          }

          ChoiceRow {
            width: parent.width
            label: win.dock.tr("clickAction")
            options: win.clickChoices
            current: win.config.clickAction
            onChosen: function(value) { win.config.setClickAction(value) }
          }

          ToggleRow {
            width: parent.width
            label: win.dock.tr("isolateMonitors")
            hint: win.dock.tr("isolateHint")
            checked: win.config.isolateMonitors
            onToggled: function(value) { win.config.setIsolateMonitors(value) }
          }

          ToggleRow {
            width: parent.width
            label: win.dock.tr("isolateWorkspaces")
            checked: win.config.isolateWorkspaces
            onToggled: function(value) { win.config.setIsolateWorkspaces(value) }
          }

          ToggleRow {
            width: parent.width
            label: win.dock.tr("showAppsButton")
            checked: win.config.showAppsButton
            onToggled: function(value) { win.config.setShowAppsButton(value) }
          }

          ToggleRow {
            width: parent.width
            label: win.dock.tr("showTrash")
            checked: win.config.showTrash
            onToggled: function(value) { win.config.setShowTrash(value) }
          }

          ToggleRow {
            width: parent.width
            label: win.dock.tr("showDrives")
            checked: win.config.showDrives
            onToggled: function(value) { win.config.setShowDrives(value) }
          }
        }
      }

      Item {
        width: parent.width
        height: doneButton.height

        Rectangle {
          id: doneButton
          anchors.right: parent.right
          width: doneLabel.implicitWidth + 32
          height: doneLabel.implicitHeight + 16
          radius: Style.cornerRadius
          color: doneMouse.containsMouse ? Util.alpha(Color.accent, 0.35) : Util.alpha(Color.accent, 0.22)
          border.width: 1
          border.color: Color.accent

          Text {
            id: doneLabel
            anchors.centerIn: parent
            text: win.dock.tr("done")
            color: Color.popups.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPx(1)
          }

          MouseArea {
            id: doneMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: win.opened = false
          }
        }
      }
    }
  }
}
