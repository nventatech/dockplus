.pragma library

var maxBadgeKey = 128
var maxBadgeCount = 9999

function cycleDecision(windowCount, openCount, focusedIndex) {
  if (windowCount <= 0) return "launch"
  if (openCount <= 0) return "restore"
  if (focusedIndex < 0) return "focus"
  if (openCount === 1) return "minimize"
  return "cycle"
}

function nextIndex(count, current, step) {
  if (count <= 0) return -1
  if (current < 0 || current >= count) return step < 0 ? count - 1 : 0
  return ((current + step) % count + count) % count
}

function folderName(path) {
  var parts = String(path).split("/").filter(function(part) { return part !== "" })
  return parts.length > 0 ? parts[parts.length - 1] : String(path)
}

function folderIcons(path) {
  var known = {
    Downloads: "folder-download",
    Documents: "folder-documents",
    Pictures: "folder-pictures",
    Music: "folder-music",
    Videos: "folder-videos",
    Desktop: "user-desktop",
    Public: "folder-publicshare"
  }
  var name = folderName(path)
  var icons = known[name] ? [known[name]] : []
  return icons.concat(["folder", "inode-directory"])
}

function folderToken(prefix, path) {
  return prefix + String(path).replace(/\/+$/, "")
}

function badgeFrom(update) {
  var key = String(update.appId || "")
  if (!key || key.length > maxBadgeKey) return null
  var count = update.countVisible ? Math.min(maxBadgeCount, Math.max(0, Math.round(Number(update.count) || 0))) : 0
  var progress = update.progressVisible ? Math.max(0, Math.min(1, Number(update.progress) || 0)) : -1
  if (count === 0 && progress < 0) return { key: key, value: null }
  return { key: key, value: { count: count, progress: progress } }
}
