import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

PanelWindow {
  id: win

  property var dock
  property bool opened: false
  property int tab: 0

  readonly property var config: dock.config
  readonly property int borderWidth: Math.max(1, Style.space(2))
  readonly property int tabWidth: 190
  readonly property int contentWidth: 420
  readonly property var tabs: [
    { key: "tabAppearance", glyph: String.fromCodePoint(0xF03D8) },
    { key: "tabPosition", glyph: String.fromCodePoint(0xF0379) },
    { key: "tabBehavior", glyph: String.fromCodePoint(0xF037D) },
    { key: "tabItems", glyph: String.fromCodePoint(0xF0570) }
  ]
  readonly property var positionChoices: [
    { value: "bottom", label: dock.tr("positionBottom") },
    { value: "left", label: dock.tr("positionLeft") },
    { value: "right", label: dock.tr("positionRight") }
  ]
  readonly property var clickChoices: [
    { value: "smart", label: dock.tr("clickSmart") },
    { value: "cycle", label: dock.tr("clickCycle") },
    { value: "launch", label: dock.tr("clickLaunch") }
  ]
  readonly property var indicatorChoices: [
    { value: "default", label: dock.tr("indicatorDefault") },
    { value: "dots", label: dock.tr("indicatorDots") },
    { value: "dashes", label: dock.tr("indicatorDashes") },
    { value: "segments", label: dock.tr("indicatorSegments") }
  ]
  readonly property var monitorChoices: {
    var choices = [{ value: "", label: dock.tr("allMonitors") }]
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++) choices.push({ value: screens[i].name, label: screens[i].name })
    return choices
  }

  function stepTab(step) {
    tab = (tab + step + tabs.length) % tabs.length
  }

  onOpenedChanged: {
    if (!opened) return
    screen = dock.focusedScreen()
    keys.forceActiveFocus()
  }

  visible: opened
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "omarchy-dock-settings"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Rectangle {
    id: keys
    anchors.fill: parent
    color: Color.menu.scrim
    focus: true

    Keys.onEscapePressed: win.opened = false
    Keys.onPressed: function(event) {
      if (!(event.modifiers & Qt.ControlModifier)) return
      if (event.key !== Qt.Key_Tab && event.key !== Qt.Key_Backtab) return
      var back = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier)
      win.stepTab(back ? -1 : 1)
      event.accepted = true
    }

    MouseArea {
      anchors.fill: parent
      onClicked: win.opened = false
    }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 24 + win.tabWidth + 24 + win.contentWidth + 24
    height: footer.y + footer.height + 24
    radius: Style.cornerRadius
    color: Color.popups.background
    border.width: win.borderWidth
    border.color: Color.popups.border

    MouseArea { anchors.fill: parent }

    Column {
      id: tabColumn
      x: 24
      y: 24 + header.height + 12
      width: win.tabWidth
      spacing: 4

      Repeater {
        model: win.tabs.length

        Rectangle {
          id: tabButton
          required property int index
          readonly property bool active: win.tab === index

          width: parent.width
          height: tabLabel.implicitHeight + 18
          radius: Style.cornerRadius
          color: active ? Util.alpha(Color.accent, 0.18)
            : tabMouse.containsMouse ? Util.alpha(Color.popups.text, 0.08) : "transparent"

          Rectangle {
            visible: tabButton.active
            x: 0
            y: 6
            width: 3
            height: parent.height - 12
            radius: 1
            color: Color.accent
          }

          Text {
            id: tabGlyph
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            text: win.tabs[tabButton.index].glyph
            color: tabButton.active ? Color.accent : Color.popups.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPx(1.3)
          }

          Text {
            id: tabLabel
            x: 44
            anchors.verticalCenter: parent.verticalCenter
            text: win.dock.tr(win.tabs[tabButton.index].key)
            color: Color.popups.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPx(1)
            font.bold: tabButton.active
          }

          MouseArea {
            id: tabMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: win.tab = tabButton.index
          }
        }
      }
    }

    Column {
      id: header
      x: 24 + win.tabWidth + 24
      y: 24
      width: win.contentWidth
      spacing: 4

      Text {
        text: win.dock.tr("settingsTitle").toUpperCase()
        color: Color.accent
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPx(1.7)
        font.bold: true
      }

      Text {
        text: win.dock.tr(win.tabs[win.tab].key).toUpperCase()
        color: Color.accent
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPx(1)
        font.bold: true
      }

      Item { width: 1; height: 6 }

      Rectangle {
        width: parent.width
        height: 1
        color: Util.alpha(Color.popups.text, 0.2)
      }
    }

    Item {
      id: pages
      x: header.x
      y: header.y + header.height + 18
      width: win.contentWidth
      height: Math.max(appearancePage.implicitHeight, positionPage.implicitHeight,
        behaviorPage.implicitHeight, itemsPage.implicitHeight, tabColumn.implicitHeight - 6)

      Column {
        id: appearancePage
        visible: win.tab === 0
        width: parent.width
        spacing: 22

        SliderRow {
          width: parent.width
          label: win.dock.tr("iconSize")
          valueText: win.config.iconSize + " px"
          ratio: (win.config.iconSize - win.config.minIconSize) / (win.config.maxIconSize - win.config.minIconSize)
          onMoved: function(ratio) {
            var value = win.config.minIconSize + ratio * (win.config.maxIconSize - win.config.minIconSize)
            win.config.setIconSize(Math.round(value / 4) * 4)
          }
        }

        SliderRow {
          width: parent.width
          label: win.dock.tr("backgroundOpacity")
          valueText: win.config.backgroundOpacity + "%"
          ratio: (win.config.backgroundOpacity - win.config.minOpacity) / (100 - win.config.minOpacity)
          onMoved: function(ratio) {
            var value = win.config.minOpacity + ratio * (100 - win.config.minOpacity)
            win.config.setBackgroundOpacity(Math.round(value / 5) * 5)
          }
        }

        ChoiceRow {
          width: parent.width
          label: win.dock.tr("indicatorStyle")
          options: win.indicatorChoices
          current: win.config.indicatorStyle
          onChosen: function(value) { win.config.setIndicatorStyle(value) }
        }

        ToggleRow {
          width: parent.width
          label: win.dock.tr("panelMode")
          hint: win.dock.tr("panelModeHint")
          checked: win.config.panelMode
          onToggled: function(value) { win.config.setPanelMode(value) }
        }
      }

      Column {
        id: positionPage
        visible: win.tab === 1
        width: parent.width
        spacing: 22

        ChoiceRow {
          width: parent.width
          label: win.dock.tr("edge")
          options: win.positionChoices
          current: win.config.position
          onChosen: function(value) { win.config.setPosition(value) }
        }

        ChoiceRow {
          width: parent.width
          label: win.dock.tr("monitor")
          options: win.monitorChoices
          current: win.config.monitor
          onChosen: function(value) { win.config.setMonitor(value) }
        }

        ToggleRow {
          width: parent.width
          label: win.dock.tr("autohide")
          hint: win.dock.tr("autohideHint")
          checked: win.config.autohide
          onToggled: function(value) { win.config.setAutohide(value) }
        }
      }

      Column {
        id: behaviorPage
        visible: win.tab === 2
        width: parent.width
        spacing: 22

        ChoiceRow {
          width: parent.width
          label: win.dock.tr("clickAction")
          options: win.clickChoices
          stacked: true
          current: win.config.clickAction
          onChosen: function(value) { win.config.setClickAction(value) }
        }

        ToggleRow {
          width: parent.width
          label: win.dock.tr("superNumbers")
          hint: win.dock.tr("superNumbersHint")
          checked: win.config.superNumbers
          onToggled: function(value) { win.config.setSuperNumbers(value) }
        }
      }

      Column {
        id: itemsPage
        visible: win.tab === 3
        width: parent.width
        spacing: 22

        ToggleRow {
          width: parent.width
          label: win.dock.tr("showAppsButton")
          checked: win.config.showAppsButton
          onToggled: function(value) { win.config.setShowAppsButton(value) }
        }

        ToggleRow {
          width: parent.width
          label: win.dock.tr("showTrash")
          checked: win.config.showTrash
          onToggled: function(value) { win.config.setShowTrash(value) }
        }

        ToggleRow {
          width: parent.width
          label: win.dock.tr("showDrives")
          checked: win.config.showDrives
          onToggled: function(value) { win.config.setShowDrives(value) }
        }

        ToggleRow {
          width: parent.width
          label: win.dock.tr("isolateMonitors")
          hint: win.dock.tr("isolateHint")
          checked: win.config.isolateMonitors
          onToggled: function(value) { win.config.setIsolateMonitors(value) }
        }

        ToggleRow {
          width: parent.width
          label: win.dock.tr("isolateWorkspaces")
          checked: win.config.isolateWorkspaces
          onToggled: function(value) { win.config.setIsolateWorkspaces(value) }
        }
      }
    }

    Item {
      id: footer
      x: 24
      y: pages.y + pages.height + 18
      width: card.width - 48
      height: closeButton.height + 17

      Rectangle {
        width: parent.width
        height: 1
        color: Util.alpha(Color.popups.text, 0.2)
      }

      Rectangle {
        id: closeButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: closeLabel.implicitWidth + 40
        height: closeLabel.implicitHeight + 16
        radius: Style.cornerRadius
        color: closeMouse.containsMouse ? Util.alpha(Color.accent, 0.35) : Util.alpha(Color.accent, 0.22)
        border.width: 1
        border.color: Color.accent

        Text {
          id: closeLabel
          anchors.centerIn: parent
          text: win.dock.tr("close") + " (Esc)"
          color: Color.popups.text
          font.family: Style.fontFamily
          font.pixelSize: Style.fontPx(1)
        }

        MouseArea {
          id: closeMouse
          anchors.fill: parent
          hoverEnabled: true
          onClicked: win.opened = false
        }
      }
    }
  }
}
