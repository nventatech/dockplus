#!/usr/bin/env python3
import json
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

INTERFACE = "com.canonical.Unity.LauncherEntry"
SUFFIX = ".desktop"
MAX_MESSAGE = 4096
MAX_KEY = 128
MAX_COUNT = 9999


def app_id(uri):
    name = str(uri).split("://", 1)[-1].strip("/")
    if name.endswith(SUFFIX):
        name = name[: -len(SUFFIX)]
    return name


def clamp(value, low, high):
    return max(low, min(high, value))


def on_update(connection, sender, path, interface, signal, params):
    try:
        if params.get_size() > MAX_MESSAGE:
            return
        uri, props = params.unpack()
        key = app_id(uri)
        if not key or len(key) > MAX_KEY:
            return
        update = {
            "appId": key,
            "count": clamp(int(props.get("count", 0)), 0, MAX_COUNT),
            "countVisible": bool(props.get("count-visible", False)),
            "progress": clamp(float(props.get("progress", 0.0)), 0.0, 1.0),
            "progressVisible": bool(props.get("progress-visible", False)),
            "urgent": bool(props.get("urgent", False)),
        }
    except Exception:
        return
    print(json.dumps(update), flush=True)


def main():
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    bus.signal_subscribe(None, INTERFACE, "Update", None, None, Gio.DBusSignalFlags.NONE, on_update)
    GLib.MainLoop().run()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
