import QtQuick
import Quickshell
import "Logic.js" as Logic

ShellRoot {
  id: suite

  property int checks: 0
  property int failures: 0

  readonly property string usbStick: JSON.stringify({
    blockdevices: [{
      name: "sda", path: "/dev/sda", rm: true, tran: "usb", size: "32G", type: "disk",
      children: [{ name: "sda1", path: "/dev/sda1", label: "MYUSB", fstype: "vfat", mountpoint: "/run/media/me/MYUSB", size: "32G", type: "part" }]
    }]
  })

  readonly property string internalDisk: JSON.stringify({
    blockdevices: [{
      name: "nvme0n1", path: "/dev/nvme0n1", rm: false, hotplug: false, tran: "nvme", size: "1T", type: "disk",
      children: [{ name: "nvme0n1p1", path: "/dev/nvme0n1p1", fstype: "ext4", mountpoint: "/", size: "1T", type: "part" }]
    }]
  })

  readonly property string hybridIso: JSON.stringify({
    blockdevices: [{
      name: "sdb", path: "/dev/sdb", rm: true, tran: "usb", size: "8G", type: "disk", fstype: "iso9660", label: "OMARCHY",
      children: [
        { name: "sdb1", path: "/dev/sdb1", fstype: "iso9660", label: "OMARCHY", size: "8G", type: "part" },
        { name: "sdb2", path: "/dev/sdb2", fstype: "vfat", parttype: "0xef", size: "8M", type: "part" }
      ]
    }]
  })

  readonly property string blankStick: JSON.stringify({
    blockdevices: [{ name: "sdc", path: "/dev/sdc", rm: true, tran: "usb", size: "16G", type: "disk" }]
  })

  function check(name, actual, expected) {
    checks++
    var got = JSON.stringify(actual)
    var want = JSON.stringify(expected)
    if (got === want) return
    failures++
    console.log("FAIL " + name + "\n  expected " + want + "\n  got      " + got)
  }

  function devices(text) {
    return drives.parse(text).map(function(volume) { return volume.device })
  }

  function runLogic() {
    check("cycleDecision with no window", Logic.cycleDecision(0, 0, -1), "launch")
    check("cycleDecision with every window minimized", Logic.cycleDecision(2, 0, -1), "restore")
    check("cycleDecision with an unfocused window", Logic.cycleDecision(1, 1, -1), "focus")
    check("cycleDecision with the only window focused", Logic.cycleDecision(1, 1, 0), "minimize")
    check("cycleDecision with several windows open", Logic.cycleDecision(3, 3, 1), "cycle")

    check("nextIndex wraps forward", Logic.nextIndex(3, 2, 1), 0)
    check("nextIndex wraps backward", Logic.nextIndex(3, 0, -1), 2)
    check("nextIndex from nothing focused", Logic.nextIndex(3, -1, 1), 0)
    check("nextIndex from nothing focused backward", Logic.nextIndex(3, -1, -1), 2)
    check("nextIndex on an empty list", Logic.nextIndex(0, -1, 1), -1)

    check("folderName of a plain path", Logic.folderName("/home/me/Downloads"), "Downloads")
    check("folderName ignores a trailing slash", Logic.folderName("/home/me/Pictures/"), "Pictures")
    check("folderName of the root", Logic.folderName("/"), "/")
    check("folderIcons of a known folder", Logic.folderIcons("/home/me/Downloads")[0], "folder-download")
    check("folderIcons of any other folder", Logic.folderIcons("/home/me/Stuff"), ["folder", "inode-directory"])
    check("folderToken drops trailing slashes", Logic.folderToken("@folder:", "/home/me/Music//"), "@folder:/home/me/Music")

    check("badgeFrom with a visible count", Logic.badgeFrom({ appId: "discord", count: 7, countVisible: true }),
      { key: "discord", value: { count: 7, progress: -1 } })
    check("badgeFrom with a hidden count", Logic.badgeFrom({ appId: "discord", count: 7, countVisible: false }),
      { key: "discord", value: null })
    check("badgeFrom clamps progress", Logic.badgeFrom({ appId: "files", progress: 4.2, progressVisible: true }),
      { key: "files", value: { count: 0, progress: 1 } })
    check("badgeFrom without an app id", Logic.badgeFrom({ count: 3, countVisible: true }), null)
    check("badgeFrom rejects an overlong app id",
      Logic.badgeFrom({ appId: new Array(200).join("a"), count: 3, countVisible: true }), null)
    check("badgeFrom clamps a huge count", Logic.badgeFrom({ appId: "discord", count: 1e12, countVisible: true }),
      { key: "discord", value: { count: 9999, progress: -1 } })
  }

  function runDrives() {
    check("a usb stick shows its partition", devices(suite.usbStick), ["/dev/sda1"])
    check("an internal disk is ignored", devices(suite.internalDisk), [])
    check("a hybrid iso stick hides the efi partition", devices(suite.hybridIso), ["/dev/sdb1"])
    check("a stick without a filesystem is ignored", devices(suite.blankStick), [])
    check("broken output yields nothing", drives.parse("not json"), [])
    check("a mounted volume keeps its label", drives.parse(suite.usbStick)[0].label, "MYUSB")
  }

  Drives {
    id: drives
    active: false
  }

  Timer {
    running: true
    interval: 50
    onTriggered: {
      suite.runLogic()
      suite.runDrives()
      console.log(suite.failures === 0
        ? ("all " + suite.checks + " checks passed")
        : (suite.failures + " of " + suite.checks + " checks failed"))
      Qt.quit()
    }
  }
}
