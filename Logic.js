.pragma library

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
