#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import json
import subprocess


def get_devices():
    try:
        import dbus
    except ImportError:
        return {"error": "python3-dbus not installed"}

    bus = dbus.SystemBus()
    try:
        manager = dbus.Interface(
            bus.get_object("org.bluez", "/"), "org.freedesktop.DBus.ObjectManager"
        )
        objects = manager.GetManagedObjects()
    except Exception as e:
        return {
            "powered": False,
            "discovering": False,
            "connected_device": "",
            "devices": [],
        }

    adapter_props = {}
    adapter_path = None
    for path, ifaces in objects.items():
        if "org.bluez.Adapter1" in ifaces:
            adapter_path = path
            adapter_props = ifaces["org.bluez.Adapter1"]
            break

    powered = bool(adapter_props.get("Powered", False))
    discovering = bool(adapter_props.get("Discovering", False))

    connected_device = ""
    devices = []

    for path, ifaces in objects.items():
        if "org.bluez.Device1" in ifaces:
            d = ifaces["org.bluez.Device1"]
            mac = str(d.get("Address", ""))
            name = str(d.get("Alias") or d.get("Name") or mac)
            connected = bool(d.get("Connected", False))
            paired = bool(d.get("Paired", False))
            icon = str(d.get("Icon", ""))
            if connected and not connected_device:
                connected_device = name
            devices.append(
                {
                    "mac": mac,
                    "name": name,
                    "connected": connected,
                    "paired": paired,
                    "icon": icon,
                    "path": str(path),
                }
            )

    devices.sort(key=lambda x: (not x["connected"], not x["paired"], x["name"].lower()))

    return {
        "powered": powered,
        "discovering": discovering,
        "connected_device": connected_device,
        "devices": devices,
    }


def do_status():
    print(json.dumps(get_devices()))


def do_scan():
    try:
        import signal

        import dbus
        from dbus.mainloop.glib import DBusGMainLoop
        from gi.repository import GLib
    except ImportError:
        print("Required libraries for scanning not found.")
        sys.exit(1)

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    try:
        manager = dbus.Interface(
            bus.get_object("org.bluez", "/"), "org.freedesktop.DBus.ObjectManager"
        )
        objects = manager.GetManagedObjects()
        adapter_path = None
        for path, ifaces in objects.items():
            if "org.bluez.Adapter1" in ifaces:
                adapter_path = path
                break

        if not adapter_path:
            sys.exit(0)

        adapter = dbus.Interface(
            bus.get_object("org.bluez", adapter_path), "org.bluez.Adapter1"
        )
    except Exception as e:
        sys.exit(0)

    loop = GLib.MainLoop()

    def on_term(signum, frame):
        try:
            adapter.StopDiscovery()
        except:
            pass
        loop.quit()
        sys.exit(0)

    signal.signal(signal.SIGTERM, on_term)
    signal.signal(signal.SIGINT, on_term)

    def emit():
        data = get_devices()
        print(
            json.dumps({"event": "devices", "devices": data.get("devices", [])}),
            flush=True,
        )
        return True

    try:
        adapter.StartDiscovery()
    except Exception as e:
        pass  # Might already be scanning

    emit()
    GLib.timeout_add(1000, emit)
    GLib.timeout_add_seconds(120, loop.quit)  # safety timeout
    loop.run()

    try:
        adapter.StopDiscovery()
    except:
        pass


def do_toggle_power():
    data = get_devices()
    powered = data.get("powered", False)
    cmd = "off" if powered else "on"
    subprocess.run(["bluetoothctl", "power", cmd])


def do_toggle_connect(mac):
    data = get_devices()
    dev = next((d for d in data.get("devices", []) if d["mac"] == mac), None)

    if dev and dev["connected"]:
        subprocess.run(["bluetoothctl", "disconnect", mac])
    else:
        subprocess.run(["bluetoothctl", "connect", mac])


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: bluetooth.py [status|scan|toggle-power|toggle-connect <mac>]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "status":
        do_status()
    elif cmd == "scan":
        do_scan()
    elif cmd == "toggle-power":
        do_toggle_power()
    elif cmd == "toggle-connect":
        if len(sys.argv) < 3:
            sys.exit(1)
        do_toggle_connect(sys.argv[2])
