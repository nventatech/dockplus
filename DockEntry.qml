import QtQuick
import qs.Commons

Loader {
  id: loader

  required property var modelData
  required property int index

  property var dock
  property var host

  z: item && item.dragging ? 10 : 0
  sourceComponent: modelData.kind === "app" ? appEntry
    : modelData.kind === "drive" ? driveEntry
    : modelData.kind === "trash" ? trashEntry
    : appsEntry

  Component {
    id: appEntry

    DockItem {
      dock: loader.dock
      host: loader.host
      renderedIndex: loader.index
      appKey: loader.modelData.key
      acceptsDrops: entry !== null
      onFilesDropped: function(urls) { loader.dock.openWith(appKey, urls) }
    }
  }

  Component {
    id: driveEntry

    DockAction {
      readonly property var drive: loader.modelData.drive

      dock: loader.dock
      host: loader.host
      renderedIndex: loader.index
      label: drive.label || drive.size
      iconNames: ["drive-removable-media-usb", "drive-removable-media", "media-removable", "drive-harddisk"]
      marked: drive.mounted
      acceptsDrops: true
      onFilesDropped: function(urls) { loader.dock.drives.copyTo(drive, loader.dock.localPaths(urls)) }
      onActivated: loader.dock.drives.open(drive)
      menuBuilder: function(anchor) { return loader.host.driveMenu(drive) }
    }
  }

  Component {
    id: trashEntry

    DockAction {
      dock: loader.dock
      host: loader.host
      renderedIndex: loader.index
      label: loader.dock.tr("trash") + (loader.dock.trash.count > 0 ? " (" + loader.dock.trash.count + ")" : "")
      iconNames: loader.dock.trash.full ? ["user-trash-full", "user-trash"] : ["user-trash"]
      onActivated: loader.dock.trash.open()
      acceptsDrops: true
      onFilesDropped: function(urls) { loader.dock.trash.trashFiles(urls) }
      menuBuilder: function(anchor) { return loader.host.trashMenu(anchor) }
    }
  }

  Component {
    id: appsEntry

    DockAction {
      dock: loader.dock
      host: loader.host
      renderedIndex: loader.index
      label: loader.dock.tr("applications")
      glyph: appsGlyph
      onActivated: loader.dock.openAppsMenu()
      menuBuilder: function(anchor) { return loader.host.backgroundMenu() }
    }
  }

  Component {
    id: appsGlyph

    Item {
      Grid {
        anchors.centerIn: parent
        columns: 3
        spacing: Math.round(loader.host.iconSize * 0.09)

        Repeater {
          model: 9
          Rectangle {
            width: Math.round(loader.host.iconSize * 0.17)
            height: width
            radius: Math.round(width * 0.3)
            color: Color.bar.text
          }
        }
      }
    }
  }
}
