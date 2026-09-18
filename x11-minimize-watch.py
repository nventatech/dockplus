#!/usr/bin/env python3
import ctypes
import json
import sys
import time

CLIENT_MESSAGE = 33
SUBSTRUCTURE_NOTIFY_MASK = 1 << 19
ICONIC_STATE = 3
NET_WM_STATE_ADD = 1
NET_WM_STATE_TOGGLE = 2
ANY_PROPERTY_TYPE = 0


class ClientMessage(ctypes.Structure):
    _fields_ = [
        ("type", ctypes.c_int),
        ("serial", ctypes.c_ulong),
        ("send_event", ctypes.c_int),
        ("display", ctypes.c_void_p),
        ("window", ctypes.c_ulong),
        ("message_type", ctypes.c_ulong),
        ("format", ctypes.c_int),
        ("data", ctypes.c_long * 5),
    ]


class Event(ctypes.Union):
    _fields_ = [("type", ctypes.c_int), ("client", ClientMessage), ("pad", ctypes.c_long * 24)]


def load_xlib():
    xlib = ctypes.CDLL("libX11.so.6")
    xlib.XOpenDisplay.restype = ctypes.c_void_p
    xlib.XOpenDisplay.argtypes = [ctypes.c_char_p]
    xlib.XDefaultRootWindow.restype = ctypes.c_ulong
    xlib.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
    xlib.XInternAtom.restype = ctypes.c_ulong
    xlib.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
    xlib.XSelectInput.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_long]
    xlib.XNextEvent.argtypes = [ctypes.c_void_p, ctypes.POINTER(Event)]
    xlib.XFree.argtypes = [ctypes.c_void_p]
    xlib.XGetWindowProperty.argtypes = [
        ctypes.c_void_p, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_long, ctypes.c_long, ctypes.c_int,
        ctypes.c_ulong, ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_int),
        ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_void_p),
    ]
    return xlib


def read_property(xlib, display, window, atom):
    actual_type = ctypes.c_ulong()
    actual_format = ctypes.c_int()
    count = ctypes.c_ulong()
    remaining = ctypes.c_ulong()
    data = ctypes.c_void_p()
    status = xlib.XGetWindowProperty(display, window, atom, 0, 1024, 0, ANY_PROPERTY_TYPE,
                                     ctypes.byref(actual_type), ctypes.byref(actual_format),
                                     ctypes.byref(count), ctypes.byref(remaining), ctypes.byref(data))
    if status != 0 or not data.value or count.value == 0:
        return None
    try:
        if actual_format.value == 32:
            return ctypes.cast(data, ctypes.POINTER(ctypes.c_ulong))[0]
        return ctypes.string_at(data, count.value).decode("utf-8", "replace")
    finally:
        xlib.XFree(data)


def main():
    xlib = load_xlib()
    display = None
    while not display:
        display = xlib.XOpenDisplay(None)
        if not display:
            time.sleep(5)

    root = xlib.XDefaultRootWindow(display)
    atom = lambda name: xlib.XInternAtom(display, name, 0)
    change_state = atom(b"WM_CHANGE_STATE")
    net_state = atom(b"_NET_WM_STATE")
    net_hidden = atom(b"_NET_WM_STATE_HIDDEN")
    net_pid = atom(b"_NET_WM_PID")
    net_name = atom(b"_NET_WM_NAME")
    wm_name = atom(b"WM_NAME")

    xlib.XSelectInput(display, root, SUBSTRUCTURE_NOTIFY_MASK)
    event = Event()
    while True:
        xlib.XNextEvent(display, ctypes.byref(event))
        if event.type != CLIENT_MESSAGE:
            continue
        message = event.client
        iconify = message.message_type == change_state and message.data[0] == ICONIC_STATE
        hidden = (message.message_type == net_state
                  and message.data[0] in (NET_WM_STATE_ADD, NET_WM_STATE_TOGGLE)
                  and net_hidden in (message.data[1] & 0xFFFFFFFF, message.data[2] & 0xFFFFFFFF))
        if not (iconify or hidden):
            continue
        title = read_property(xlib, display, message.window, net_name) or read_property(xlib, display, message.window, wm_name)
        print(json.dumps({
            "pid": read_property(xlib, display, message.window, net_pid) or 0,
            "title": title or "",
        }), flush=True)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
