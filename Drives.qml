import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property bool active: true
  property var listCommand: ["lsblk", "-J", "-o", "NAME,PATH,LABEL,MOUNTPOINT,RM,HOTPLUG,TRAN,SIZE,FSTYPE,TYPE,PARTTYPE"]
  property var drives: []

  readonly property var skippedFilesystems: ["swap", "crypto_LUKS", "LVM2_member", "linux_raid_member"]
  readonly property var systemMountpoints: ["/", "/boot", "/boot/efi", "/efi", "/home", "[SWAP]"]
  readonly property var efiPartitionTypes: ["0xef", "c12a7328-f81f-11d2-ba4b-00a0c93ec93b"]

  function flag(value) {
    return value === true || value === 1 || value === "1"
  }

  function removable(node) {
    return flag(node.rm) || flag(node.hotplug) || node.tran === "usb"
  }

  function volumeFrom(node, disk) {
    if (!node.fstype || skippedFilesystems.indexOf(node.fstype) !== -1) return null
    if (efiPartitionTypes.indexOf(String(node.parttype || "").toLowerCase()) !== -1) return null
    if (node.mountpoint && systemMountpoints.indexOf(node.mountpoint) !== -1) return null
    return {
      device: String(node.path || ("/dev/" + node.name)),
      disk: String(disk.path || ("/dev/" + disk.name)),
      label: String(node.label || ""),
      size: String(node.size || ""),
      mountpoint: String(node.mountpoint || ""),
      mounted: !!node.mountpoint
    }
  }

  function parse(text) {
    var tree = null
    try { tree = JSON.parse(text) } catch (error) { return [] }
    var found = []
    var disks = tree && tree.blockdevices ? tree.blockdevices : []
    for (var i = 0; i < disks.length; i++) {
      var disk = disks[i]
      if (!removable(disk)) continue
      var nodes = disk.children && disk.children.length > 0 ? disk.children : [disk]
      for (var j = 0; j < nodes.length; j++) {
        var volume = volumeFrom(nodes[j], disk)
        if (volume) found.push(volume)
      }
    }
    return found
  }

  function refresh() {
    if (active && !listing.running) listing.running = true
  }

  function run(script, args) {
    Quickshell.execDetached(["sh", "-c", script, "sh"].concat(args))
  }

  function open(drive) {
    if (drive.mounted) {
      Quickshell.execDetached(["gio", "open", drive.mountpoint])
      return
    }
    run('out=$(udisksctl mount -b "$1" 2>&1) || { notify-send "Dock" "$out"; exit 1; }\n'
      + 'path=$(printf "%s\\n" "$out" | sed -n "s/^Mounted .* at \\(.*\\)$/\\1/p")\n'
      + 'path=${path%.}\n'
      + '[ -n "$path" ] && gio open "$path"', [drive.device])
  }

  function unmount(drive) {
    run('out=$(udisksctl unmount -b "$1" 2>&1) || notify-send "Dock" "$out"', [drive.device])
  }

  function eject(drive) {
    var mounted = drives.filter(function(other) { return other.disk === drive.disk && other.mounted })
      .map(function(other) { return other.device })
    run('disk=$1; shift\n'
      + 'for device in "$@"; do out=$(udisksctl unmount -b "$device" 2>&1) || { notify-send "Dock" "$out"; exit 1; }; done\n'
      + 'out=$(udisksctl power-off -b "$disk" 2>&1) || notify-send "Dock" "$out"', [drive.disk].concat(mounted))
  }

  onActiveChanged: {
    if (active) refresh()
    else drives = []
  }

  Process {
    id: listing
    command: root.listCommand
    stdout: StdioCollector { onStreamFinished: root.drives = root.active ? root.parse(text) : [] }
  }

  Process {
    id: monitor
    running: root.active
    command: ["udisksctl", "monitor"]
    stdout: SplitParser { onRead: settle.restart() }
    onExited: if (root.active) monitorRestart.restart()
  }

  Timer { id: settle; interval: 400; onTriggered: root.refresh() }
  Timer { id: monitorRestart; interval: 5000; onTriggered: monitor.running = root.active }

  Timer {
    interval: 10000
    running: root.active
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
