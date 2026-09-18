import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

Rectangle {
  id: card

  property var dock
  property var toplevel
  property int cardWidth: 200
  property bool selected: false
  property bool showMinimizedState: true

  readonly property int thumbHeight: Math.round(cardWidth * 0.6)
  readonly property bool minimized: toplevel ? dock.isMinimized(toplevel) : false
  readonly property bool dimmed: minimized && showMinimizedState
  readonly property bool hovered: cardMouse.containsMouse || closeMouse.containsMouse
  readonly property string appId: toplevel ? dock.appIdOf(toplevel) : ""

  signal picked()
  signal closeRequested()

  width: cardWidth
  height: thumbHeight + cardTitle.implicitHeight + 18
  radius: Style.cornerRadius
  color: hovered || selected ? Util.alpha(Color.popups.text, 0.1) : "transparent"
  border.width: selected ? 2 : (toplevel && toplevel.activated ? 1 : 0)
  border.color: Color.accent

  Item {
    id: thumbBox
    x: 6
    y: 6
    width: parent.width - 12
    height: card.thumbHeight

    ScreencopyView {
      id: thumb
      anchors.centerIn: parent
      opacity: card.dimmed ? 0.45 : 1
      captureSource: card.toplevel ? card.toplevel.wayland : null
      live: true
      constraintSize: Qt.size(thumbBox.width, thumbBox.height)
    }

    Image {
      anchors.centerIn: parent
      visible: !thumb.hasContent
      width: 48
      height: 48
      sourceSize: Qt.size(48, 48)
      source: card.dock.iconFor(card.appId, card.dock.entryFor(card.appId))
    }
  }

  Rectangle {
    visible: card.dimmed
    x: 10
    y: 10
    width: badge.implicitWidth + 10
    height: badge.implicitHeight + 4
    radius: Style.cornerRadius
    color: Color.popups.background
    border.width: 1
    border.color: Util.alpha(Color.popups.text, 0.4)

    Text {
      id: badge
      anchors.centerIn: parent
      text: card.dock.tr("minimized")
      color: Color.popups.text
      font.family: Style.fontFamily
      font.pixelSize: Style.fontPx(0.8)
    }
  }

  Text {
    id: cardTitle
    x: 6
    y: thumbBox.y + thumbBox.height + 6
    width: parent.width - 12
    text: card.toplevel ? card.toplevel.title || "" : ""
    color: Color.popups.text
    font.family: Style.fontFamily
    font.pixelSize: Style.fontPx(0.9)
    elide: Text.ElideRight
    maximumLineCount: 1
    horizontalAlignment: Text.AlignHCenter
  }

  MouseArea {
    id: cardMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: function(event) {
      if (event.button === Qt.MiddleButton) card.closeRequested()
      else card.picked()
    }
  }

  Rectangle {
    visible: card.hovered
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 8
    width: 20
    height: 20
    radius: Math.min(10, Style.cornerRadius + 2)
    color: closeMouse.containsMouse ? Color.urgent : Color.popups.background
    border.width: 1
    border.color: Util.alpha(Color.popups.text, 0.4)

    Text {
      anchors.centerIn: parent
      text: "×"
      color: Color.popups.text
      font.family: Style.fontFamily
      font.pixelSize: Style.fontPx(1.1)
    }

    MouseArea {
      id: closeMouse
      anchors.fill: parent
      hoverEnabled: true
      onClicked: card.closeRequested()
    }
  }
}
