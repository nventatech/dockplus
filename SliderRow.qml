import QtQuick
import qs.Commons

Column {
  id: row

  property string label: ""
  property string valueText: ""
  property real ratio: 0

  signal moved(real ratio)

  spacing: 10

  Item {
    width: parent.width
    height: title.implicitHeight

    Text {
      id: title
      text: row.label
      color: Color.popups.text
      font.family: Style.fontFamily
      font.pixelSize: Style.fontPx(1)
    }

    Text {
      anchors.right: parent.right
      text: row.valueText
      color: Util.alpha(Color.popups.text, 0.6)
      font.family: Style.fontFamily
      font.pixelSize: Style.fontPx(1)
    }
  }

  Item {
    id: track
    width: parent.width
    height: 24

    function apply(position) {
      row.moved(Math.max(0, Math.min(1, position / width)))
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: 4
      radius: 2
      color: Util.alpha(Color.popups.text, 0.2)

      Rectangle {
        width: Math.round(parent.width * row.ratio)
        height: parent.height
        radius: 2
        color: Color.accent
      }
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      x: Math.round((parent.width - width) * row.ratio)
      width: 16
      height: 16
      radius: Math.min(8, Style.cornerRadius + 2)
      color: Color.accent
    }

    MouseArea {
      anchors.fill: parent
      onPressed: function(event) { track.apply(event.x) }
      onPositionChanged: function(event) { if (pressed) track.apply(event.x) }
    }
  }
}
