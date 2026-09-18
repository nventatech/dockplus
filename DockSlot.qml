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
  property real lastWheel: 0
  property bool acceptsDrops: false
  property bool activatesOnDrag: false

  default property alias content: body.data

  readonly property bool dragging: mouse.drag.active
  readonly property bool pressed: mouse.pressed
  readonly property bool hovered: mouse.containsMouse
  readonly property real iconX: host.itemPadding + (host.position === "left" ? host.indicatorSpace : 0)
  readonly property real iconY: host.itemPadding
  readonly property int lastIndex: host.entries.length - 1

  signal clicked(int button)
  signal scrolled(int step)
  signal filesDropped(var urls)
  signal dragHeld()

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
    if (target >= 0 && target !== from) owner.moveRendered(host.entries, from, target)
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
      color: drop.containsDrag ? Util.alpha(Color.accent, 0.3)
        : Util.alpha(Color.bar.text, slot.pressed ? 0.16 : slot.hovered ? 0.09 : 0)
      Behavior on color { ColorAnimation { duration: 100 } }
    }
  }

  DropArea {
    id: drop
    anchors.fill: parent
    enabled: slot.acceptsDrops || slot.activatesOnDrag
    keys: ["text/uri-list"]
    onEntered: {
      slot.host.fileDragEnter()
      if (slot.activatesOnDrag) dragHoldTimer.restart()
    }
    onExited: {
      dragHoldTimer.stop()
      slot.host.fileDragLeave()
    }
    onDropped: function(event) {
      dragHoldTimer.stop()
      if (!slot.acceptsDrops) {
        slot.host.fileDragDone()
        return
      }
      var urls = []
      for (var i = 0; i < event.urls.length; i++) urls.push(String(event.urls[i]))
      event.acceptProposedAction()
      slot.host.fileDragDone()
      if (urls.length > 0) slot.filesDropped(urls)
    }
  }

  Timer {
    id: dragHoldTimer
    interval: 700
    onTriggered: if (drop.containsDrag) slot.dragHeld()
  }

  Rectangle {
    visible: slot.host.numbersVisible && slot.renderedIndex >= 0 && slot.renderedIndex < 9
    z: 5
    x: slot.iconX - 4
    y: slot.iconY - 4
    width: Math.max(height, numberLabel.implicitWidth + 8)
    height: numberLabel.implicitHeight + 4
    radius: height / 2
    color: Color.accent

    Text {
      id: numberLabel
      anchors.centerIn: parent
      text: slot.renderedIndex + 1
      color: Color.bar.background
      font.family: Style.fontFamily
      font.pixelSize: Style.fontPx(0.9)
      font.bold: true
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
    onWheel: function(wheel) {
      var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
      var now = Date.now()
      if (delta === 0 || now - slot.lastWheel < 250) return
      slot.lastWheel = now
      slot.scrolled(delta < 0 ? 1 : -1)
    }
  }

  Component.onDestruction: host.setHovered(slot, false)
}
