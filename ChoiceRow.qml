import QtQuick
import qs.Commons

Column {
  id: row

  property string label: ""
  property var options: []
  property string current: ""

  signal chosen(string value)

  spacing: 10

  Text {
    text: row.label
    color: Color.popups.text
    font.family: Style.fontFamily
    font.pixelSize: Style.fontPx(1)
  }

  ChoiceChips {
    width: parent.width
    options: row.options
    current: row.current
    onChosen: function(value) { row.chosen(value) }
  }
}
