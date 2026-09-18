import QtQuick
import Quickshell
import qs.Commons

Item {
  id: item

  property var host
  property string label: ""
  property var iconNames: []
  property Component glyph: null
  property bool marked: false
  property var menuBuilder: null

  readonly property string iconSource: {
    for (var i = 0; i < iconNames.length; i++) {
      var path = Quickshell.iconPath(iconNames[i], true)
      if (path) return path
    }
    return ""
  }
  readonly property real iconX: host.itemPadding + (host.position === "left" ? host.indicatorSpace : 0)

  signal activated()

  width: host.iconSize + host.itemPadding * 2 + (host.vertical ? host.indicatorSpace : 0)
  height: host.iconSize + host.itemPadding * 2 + (host.vertical ? 0 : host.indicatorSpace)

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: Util.alpha(Color.bar.text, mouse.pressed ? 0.16 : mouse.containsMouse ? 0.09 : 0)
    Behavior on color { ColorAnimation { duration: 100 } }
  }

  Item {
    x: item.iconX
    y: item.host.itemPadding
    width: item.host.iconSize
    height: item.host.iconSize
    scale: mouse.pressed ? 0.9 : mouse.containsMouse ? 1.1 : 1
    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

    Image {
      anchors.fill: parent
      visible: item.glyph === null
      sourceSize: Qt.size(item.host.iconSize, item.host.iconSize)
      source: item.iconSource
      asynchronous: true
      smooth: true
    }

    Loader {
      anchors.fill: parent
      active: item.glyph !== null
      sourceComponent: item.glyph
    }
  }

  Rectangle {
    visible: item.marked
    x: !item.host.vertical ? Math.round((parent.width - width) / 2)
      : item.host.position === "left" ? 1 : parent.width - width - 1
    y: item.host.vertical ? Math.round((parent.height - height) / 2) : parent.height - height - 1
    width: 4
    height: 4
    radius: 2
    color: Util.alpha(Color.bar.text, 0.7)
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onContainsMouseChanged: item.host.setHovered(item, containsMouse)
    onClicked: function(event) {
      if (event.button === Qt.LeftButton) {
        item.activated()
        return
      }
      var entries = typeof item.menuBuilder === "function" ? item.menuBuilder() : []
      if (entries.length > 0) item.host.openMenu(item, entries)
    }
  }

  Component.onDestruction: host.setHovered(item, false)
}
