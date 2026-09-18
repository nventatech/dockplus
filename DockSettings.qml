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
  readonly property var positionChoices: [
    { value: "bottom", label: dock.tr("positionBottom") },
    { value: "left", label: dock.tr("positionLeft") },
    { value: "right", label: dock.tr("positionRight") }
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
    width: 440
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
      width: parent.width - 48
      spacing: 22

      Text {
        text: win.dock.tr("settingsTitle")
        color: Color.popups.text
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPx(1.4)
        font.bold: true
      }

      Item {
        width: parent.width
        height: Math.max(autohideLabels.implicitHeight, 24)

        Column {
          id: autohideLabels
          width: parent.width - 64
          spacing: 3

          Text {
            text: win.dock.tr("autohide")
            color: Color.popups.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPx(1)
          }

          Text {
            width: parent.width
            text: win.dock.tr("autohideHint")
            color: Util.alpha(Color.popups.text, 0.6)
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPx(0.9)
            wrapMode: Text.WordWrap
          }
        }

        Rectangle {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: 44
          height: 24
          radius: Math.min(12, Style.cornerRadius + 2)
          color: win.config.autohide ? Color.accent : Util.alpha(Color.popups.text, 0.2)
          Behavior on color { ColorAnimation { duration: 120 } }

          Rectangle {
            width: 18
            height: 18
            y: 3
            x: win.config.autohide ? parent.width - width - 3 : 3
            radius: Math.min(9, Style.cornerRadius)
            color: Color.popups.background
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            onClicked: win.config.setAutohide(!win.config.autohide)
          }
        }
      }

      Column {
        width: parent.width
        spacing: 10

        Item {
          width: parent.width
          height: sizeLabel.implicitHeight

          Text {
            id: sizeLabel
            text: win.dock.tr("iconSize")
            color: Color.popups.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPx(1)
          }

          Text {
            anchors.right: parent.right
            text: win.config.iconSize + " px"
            color: Util.alpha(Color.popups.text, 0.6)
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPx(1)
          }
        }

        Item {
          id: slider
          width: parent.width
          height: 24

          readonly property real ratio: (win.config.iconSize - win.config.minIconSize)
            / (win.config.maxIconSize - win.config.minIconSize)

          function apply(position) {
            var clamped = Math.max(0, Math.min(1, position / width))
            var value = win.config.minIconSize + clamped * (win.config.maxIconSize - win.config.minIconSize)
            win.config.setIconSize(Math.round(value / 4) * 4)
          }

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Util.alpha(Color.popups.text, 0.2)

            Rectangle {
              width: Math.round(parent.width * slider.ratio)
              height: parent.height
              radius: 2
              color: Color.accent
            }
          }

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: Math.round((parent.width - width) * slider.ratio)
            width: 16
            height: 16
            radius: Math.min(8, Style.cornerRadius + 2)
            color: Color.accent
          }

          MouseArea {
            anchors.fill: parent
            onPressed: function(event) { slider.apply(event.x) }
            onPositionChanged: function(event) { if (pressed) slider.apply(event.x) }
          }
        }
      }

      Column {
        width: parent.width
        spacing: 10

        Text {
          text: win.dock.tr("position")
          color: Color.popups.text
          font.family: Style.fontFamily
          font.pixelSize: Style.fontPx(1)
        }

        ChoiceChips {
          width: parent.width
          options: win.positionChoices
          current: win.config.position
          onChosen: function(value) { win.config.setPosition(value) }
        }
      }

      Column {
        width: parent.width
        spacing: 10

        Text {
          text: win.dock.tr("monitor")
          color: Color.popups.text
          font.family: Style.fontFamily
          font.pixelSize: Style.fontPx(1)
        }

        ChoiceChips {
          width: parent.width
          options: win.monitorChoices
          current: win.config.monitor
          onChosen: function(value) { win.config.setMonitor(value) }
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
