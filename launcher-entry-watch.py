#!/usr/bin/env python3
import json
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

INTERFACE = "com.canonical.Unity.LauncherEntry"
SUFFIX = ".desktop"


def app_id(uri):
    name = str(uri).split("://", 1)[-1].strip("/")
    if name.endswith(SUFFIX):
        name = name[: -len(SUFFIX)]
    return name


def on_update(connection, sender, path, interface, signal, params):
    try:
        uri, props = params.unpack()
    except Exception:
        return
    key = app_id(uri)
    if not key:
        return
    print(json.dumps({
        "appId": key,
        "count": int(props.get("count", 0)),
        "countVisible": bool(props.get("count-visible", False)),
        "progress": float(props.get("progress", 0.0)),
        "progressVisible": bool(props.get("progress-visible", False)),
        "urgent": bool(props.get("urgent", False)),
    }), flush=True)


def main():
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    bus.signal_subscribe(None, INTERFACE, "Update", None, None, Gio.DBusSignalFlags.NONE, on_update)
    GLib.MainLoop().run()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
