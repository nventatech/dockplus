import QtQuick
import qs.Commons

Item {
  id: row

  property string label: ""
  property string hint: ""
  property bool checked: false

  signal toggled(bool value)

  height: Math.max(labels.implicitHeight, 24)

  Column {
    id: labels
    width: parent.width - 64
    spacing: 3

    Text {
      text: row.label
      color: Color.popups.text
      font.family: Style.fontFamily
      font.pixelSize: Style.fontPx(1)
    }

    Text {
      visible: row.hint !== ""
      width: parent.width
      text: row.hint
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
    color: row.checked ? Color.accent : Util.alpha(Color.popups.text, 0.2)
    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
      width: 18
      height: 18
      y: 3
      x: row.checked ? parent.width - width - 3 : 3
      radius: Math.min(9, Style.cornerRadius)
      color: Color.popups.background
      Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    MouseArea {
      anchors.fill: parent
      anchors.margins: -6
      onClicked: row.toggled(!row.checked)
    }
  }
}
