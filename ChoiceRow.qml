import QtQuick
import qs.Commons

Column {
  id: row

  property string label: ""
  property var options: []
  property string current: ""
  property bool stacked: false

  signal chosen(string value)

  spacing: 10

  Text {
    textFormat: Text.PlainText
    text: row.label
    color: Color.popups.text
    font.family: Style.fontFamily
    font.pixelSize: Style.fontPx(1)
  }

  ChoiceChips {
    width: parent.width
    options: row.options
    current: row.current
    stacked: row.stacked
    onChosen: function(value) { row.chosen(value) }
  }
}
