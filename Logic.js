.pragma library

function nextIndex(count, current, step) {
  if (count <= 0) return -1
  if (current < 0 || current >= count) return step < 0 ? count - 1 : 0
  return ((current + step) % count + count) % count
}
