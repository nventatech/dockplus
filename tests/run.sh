#!/bin/sh
set -e

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cp "$root/Logic.js" "$root/Drives.qml" "$root/tests/shell.qml" "$work/"

out=$(quickshell -p "$work/shell.qml" 2>&1)
echo "$out" | grep -E "FAIL|checks (passed|failed)" || true
echo "$out" | grep -q "checks passed"
