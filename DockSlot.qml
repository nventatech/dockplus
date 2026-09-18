import QtQuick
import qs.Commons

Item {
  id: slot

  property var dock
  property var host
  property int renderedIndex: -1
  property string label: ""
  property int dropIndex: -1
  property bool wasDragged: false

  default property alias content: body.data

  readonly property bool dragging: mouse.drag.active
  readonly property bool pressed: mouse.pressed
  readonly property bool hovered: mouse.containsMouse
  readonly property real iconX: host.itemPadding + (host.position === "left" ? host.indicatorSpace : 0)
  readonly property real iconY: host.itemPadding
  readonly property int lastIndex: dock.entries.length - 1

  signal clicked(int button)

  function updateDrop() {
    var center = renderedIndex * host.slotSize + host.slotSize / 2 + (host.vertical ? body.y : body.x)
    dropIndex = Math.max(0, Math.min(lastIndex, Math.floor(center / host.slotSize)))
  }

  onDraggingChanged: {
    if (dragging) {
      wasDragged = true
      host.dragItem = slot
      updateDrop()
      return
    }
    var owner = dock
    var from = renderedIndex
    var target = dropIndex
    body.x = 0
    body.y = 0
    dropIndex = -1
    host.dragItem = null
    if (target >= 0 && target !== from) owner.moveRendered(from, target)
  }

  width: host.iconSize + host.itemPadding * 2 + (host.vertical ? host.indicatorSpace : 0)
  height: host.iconSize + host.itemPadding * 2 + (host.vertical ? 0 : host.indicatorSpace)

  Item {
    id: body
    width: parent.width
    height: parent.height
    scale: slot.dragging ? 1.06 : 1
    onXChanged: if (slot.dragging) slot.updateDrop()
    onYChanged: if (slot.dragging) slot.updateDrop()

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: Util.alpha(Color.bar.text, slot.pressed ? 0.16 : slot.hovered ? 0.09 : 0)
      Behavior on color { ColorAnimation { duration: 100 } }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    drag.target: body
    drag.axis: slot.host.vertical ? Drag.YAxis : Drag.XAxis
    drag.minimumX: -slot.renderedIndex * slot.host.slotSize
    drag.maximumX: (slot.lastIndex - slot.renderedIndex) * slot.host.slotSize
    drag.minimumY: drag.minimumX
    drag.maximumY: drag.maximumX
    onPressed: slot.wasDragged = false
    onContainsMouseChanged: slot.host.setHovered(slot, containsMouse)
    onClicked: function(event) {
      if (!slot.wasDragged) slot.clicked(event.button)
    }
  }

  Component.onDestruction: host.setHovered(slot, false)
}
