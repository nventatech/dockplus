import QtQuick
import qs.Commons

Flow {
  id: chips

  property var options: []
  property string current: ""
  property bool stacked: false

  signal chosen(string value)

  spacing: 8

  Repeater {
    model: chips.options.length

    Rectangle {
      id: chip
      required property int index
      readonly property var option: chips.options[index]
      readonly property bool selected: chips.current === option.value

      width: chips.stacked ? chips.width : chipLabel.implicitWidth + 24
      height: chipLabel.implicitHeight + 14
      radius: Style.cornerRadius
      color: selected ? Util.alpha(Color.accent, 0.22)
        : chipMouse.containsMouse ? Util.alpha(Color.popups.text, 0.08) : "transparent"
      border.width: 1
      border.color: selected ? Color.accent : Util.alpha(Color.popups.text, 0.3)

      Text {
        id: chipLabel
        x: chips.stacked ? 12 : Math.round((parent.width - width) / 2)
        anchors.verticalCenter: parent.verticalCenter
        text: chip.option.label
        color: Color.popups.text
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPx(1)
      }

      MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: chips.chosen(chip.option.value)
      }
    }
  }
}
