import QtQuick
import Quickshell
import qs.Commons

DockSlot {
  id: item

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

  signal activated()

  onClicked: function(button) {
    if (button === Qt.LeftButton) {
      activated()
      return
    }
    if (button !== Qt.RightButton) return
    var entries = typeof menuBuilder === "function" ? menuBuilder(item) : []
    if (entries.length > 0) host.openMenu(item, entries)
  }

  Item {
    x: item.iconX
    y: item.iconY
    width: item.host.iconSize
    height: item.host.iconSize
    scale: item.iconScale
    Behavior on scale { NumberAnimation { duration: item.host.duration(110); easing.type: Easing.OutCubic } }

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
}
