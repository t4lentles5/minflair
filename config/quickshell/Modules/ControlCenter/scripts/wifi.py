#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import json
import subprocess


def get_wifi_device():
    try:
        res = subprocess.run(
            ["nmcli", "-t", "-f", "DEVICE,TYPE", "device"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        for line in res.stdout.strip().splitlines():
            parts = line.split(":")
            if len(parts) >= 2 and parts[1] == "wifi":
                return parts[0]
    except Exception:
        pass
    return None


def get_saved_connections():
    saved = set()
    try:
        res = subprocess.run(
            ["nmcli", "-t", "-f", "NAME,TYPE,TIMESTAMP", "connection", "show"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        for line in res.stdout.strip().splitlines():
            if ":" in line:
                parts = line.split(":")
                if len(parts) >= 2:
                    name = parts[0]
                    conn_type = parts[1]
                    timestamp = 0
                    if len(parts) >= 3:
                        try:
                            timestamp = int(parts[2])
                        except ValueError:
                            timestamp = 0
                    if conn_type in ("802-11-wireless", "wifi") and timestamp > 0:
                        saved.add(name.strip())
    except Exception:
        pass
    return saved


def get_status():
    radio = False
    connected_ssid = "Disconnected"
    try:
        res = subprocess.run(
            ["nmcli", "radio", "wifi"], capture_output=True, text=True, timeout=5
        )
        radio = res.stdout.strip() == "enabled"
    except Exception:
        pass

    try:
        res = subprocess.run(
            ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        for line in res.stdout.strip().splitlines():
            if line.startswith("wifi:"):
                parts = line.split(":")
                if len(parts) >= 3 and parts[1] == "connected":
                    connected_ssid = parts[2]
                break
    except Exception:
        pass

    return {"radio": radio, "connected_ssid": connected_ssid}


def scan_networks(rescan=True):
    saved = get_saved_connections()
    networks = []
    seen = {}

    cmd = [
        "nmcli",
        "-t",
        "-f",
        "SSID,SIGNAL,IN-USE,SECURITY",
        "device",
        "wifi",
        "list",
    ]
    if rescan:
        cmd.extend(["--rescan", "yes"])
    else:
        cmd.extend(["--rescan", "no"])

    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        for raw_line in res.stdout.strip().splitlines():
            if not raw_line:
                continue
            line = raw_line.replace(r"\:", "__COLON__")
            parts = line.split(":")
            if len(parts) < 4:
                continue
            ssid = parts[0].replace("__COLON__", ":").strip()
            if not ssid:
                continue
            try:
                signal = int(parts[1])
            except ValueError:
                signal = 0
            in_use = parts[2].strip() == "*"
            security = parts[3].replace("__COLON__", ":").strip()

            is_saved = in_use or (ssid in saved)

            if ssid in seen:
                idx = seen[ssid]
                if in_use or signal > networks[idx]["signal"]:
                    networks[idx]["signal"] = max(networks[idx]["signal"], signal)
                    networks[idx]["active"] = networks[idx]["active"] or in_use
                    networks[idx]["saved"] = networks[idx]["saved"] or is_saved
            else:
                seen[ssid] = len(networks)
                networks.append(
                    {
                        "ssid": ssid,
                        "signal": signal,
                        "active": in_use,
                        "saved": is_saved,
                        "security": security,
                    }
                )
    except Exception:
        pass

    networks.sort(
        key=lambda x: (not x["active"], not x["saved"], -x["signal"], x["ssid"].lower())
    )
    return networks


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "scan"

    if action == "status":
        print(json.dumps(get_status()))
    elif action == "scan":
        rescan = sys.argv[2] != "no" if len(sys.argv) > 2 else True
        print(json.dumps(scan_networks(rescan)))
    elif action == "toggle-radio":
        st = get_status()
        new_state = "off" if st["radio"] else "on"
        subprocess.run(["nmcli", "radio", "wifi", new_state])
        print(json.dumps({"radio": new_state == "on"}))
    elif action == "connect" and len(sys.argv) > 2:
        ssid = sys.argv[2]
        password = sys.argv[3] if len(sys.argv) > 3 else None
        saved = get_saved_connections()

        if ssid in saved and not password:
            res = subprocess.run(
                ["nmcli", "connection", "up", "id", ssid],
                capture_output=True,
                text=True,
            )
        else:
            cmd = ["nmcli", "device", "wifi", "connect", ssid]
            if password:
                cmd.extend(["password", password])
            res = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
            )

        if res.returncode != 0 and ssid not in saved:
            check = subprocess.run(
                ["nmcli", "-t", "-f", "NAME,TIMESTAMP", "connection", "show", ssid],
                capture_output=True,
                text=True,
            )
            for l in check.stdout.strip().splitlines():
                if ":" in l:
                    p = l.split(":", 1)
                    if p[0] == ssid and (p[1].strip() == "0" or p[1].strip() == ""):
                        subprocess.run(
                            ["nmcli", "connection", "delete", "id", ssid],
                            capture_output=True,
                        )
                        break

        print(
            json.dumps(
                {
                    "success": res.returncode == 0,
                    "output": res.stdout.strip() or res.stderr.strip(),
                }
            )
        )
    elif action == "disconnect":
        dev = get_wifi_device()
        if dev:
            subprocess.run(["nmcli", "device", "disconnect", dev])
        elif len(sys.argv) > 2:
            ssid = sys.argv[2]
            subprocess.run(["nmcli", "connection", "down", "id", ssid])
        print(json.dumps({"success": True}))
    elif action == "forget" and len(sys.argv) > 2:
        ssid = sys.argv[2]
        subprocess.run(["nmcli", "connection", "delete", "id", ssid])
        print(json.dumps({"success": True}))
    else:
        print(json.dumps(scan_networks(True)))


if __name__ == "__main__":
    main()
