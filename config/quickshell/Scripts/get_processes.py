#!/usr/bin/env python3
import json
import os
import pwd
import re
import shutil
import subprocess
import sys
import time

uid_to_user = {}
_gpu_name = "None"
_gpu_detected = False
_gpu_checked = False


def get_user_by_uid(uid):
    if uid not in uid_to_user:
        try:
            uid_to_user[uid] = pwd.getpwuid(uid).pw_name
        except Exception:
            uid_to_user[uid] = str(uid)
    return uid_to_user[uid]


def format_memory(bytes_val):
    if bytes_val >= 1024 * 1024 * 1024:
        return f"{bytes_val / (1024 * 1024 * 1024):.1f} GB"
    elif bytes_val >= 1024 * 1024:
        return f"{bytes_val / (1024 * 1024):.0f} MB"
    elif bytes_val >= 1024:
        return f"{bytes_val / 1024:.0f} KB"
    else:
        return f"{bytes_val} B"


def get_system_cpu_ticks():
    try:
        with open("/proc/stat", "r") as f:
            line = f.readline()
        if line.startswith("cpu "):
            parts = line.split()
            # user nice system idle iowait irq softirq steal
            fields = [int(p) for p in parts[1:9]]
            total = sum(fields)
            idle = fields[3] + fields[4]  # idle + iowait
            return {"total": total, "idle": idle}
    except Exception:
        pass
    return {"total": 0, "idle": 0}


def get_all_processes_ticks():
    proc_data = {}
    page_size = os.sysconf("SC_PAGE_SIZE")
    for pid_str in os.listdir("/proc"):
        if pid_str.isdigit():
            pid = int(pid_str)
            try:
                stat_info = os.stat(f"/proc/{pid}")
                uid = stat_info.st_uid

                with open(f"/proc/{pid}/stat", "r") as f:
                    stat_content = f.read()

                parts = stat_content.split(")")
                if len(parts) >= 2:
                    comm = parts[0].split("(")[1]
                    rest = parts[1].split()
                    utime = int(rest[11])
                    stime = int(rest[12])
                    rss_pages = int(rest[21])

                    cmdline = ""
                    try:
                        with open(f"/proc/{pid}/cmdline", "r") as cf:
                            raw_cmd = cf.read()
                            cmdline = raw_cmd.replace("\x00", " ").strip()
                    except Exception:
                        pass
                    if not cmdline:
                        cmdline = comm

                    proc_data[pid] = {
                        "comm": comm,
                        "utime": utime,
                        "stime": stime,
                        "rss_bytes": rss_pages * page_size,
                        "uid": uid,
                        "cmdline": cmdline,
                    }
            except (
                FileNotFoundError,
                ProcessLookupError,
                PermissionError,
                IndexError,
                ValueError,
            ):
                continue
    return proc_data


def get_system_mem():
    try:
        with open("/proc/meminfo", "r") as f:
            meminfo = {}
            for line in f:
                parts = line.split(":")
                if len(parts) == 2:
                    meminfo[parts[0].strip()] = parts[1].strip()
        total_kb = float(meminfo["MemTotal"].split()[0])
        avail_kb = float(meminfo["MemAvailable"].split()[0])
        used_kb = total_kb - avail_kb

        mem_total_gb = round(total_kb / (1024 * 1024), 1)
        mem_used_gb = round(used_kb / (1024 * 1024), 1)
        system_mem_pct = round((used_kb / total_kb) * 100, 1)
        return {
            "mem_usage": system_mem_pct,
            "mem_total_gb": mem_total_gb,
            "mem_used_gb": mem_used_gb,
        }
    except Exception:
        return {"mem_usage": 0.0, "mem_total_gb": 0.0, "mem_used_gb": 0.0}


def get_system_tasks():
    try:
        with open("/proc/loadavg", "r") as f:
            return int(f.read().split()[3].split("/")[1])
    except Exception:
        return 0


def get_cpu_temp():
    try:
        hwmon_base = "/sys/class/hwmon"
        if os.path.exists(hwmon_base):
            for hwmon in os.listdir(hwmon_base):
                hwmon_path = os.path.join(hwmon_base, hwmon)
                name_path = os.path.join(hwmon_path, "name")
                if os.path.exists(name_path):
                    with open(name_path, "r") as f:
                        name = f.read().strip()
                    if name in ["coretemp", "k10temp", "cpu_thermal", "zenpower", "Tctl"]:
                        for file in os.listdir(hwmon_path):
                            if file.startswith("temp") and file.endswith("_input"):
                                with open(os.path.join(hwmon_path, file), "r") as f:
                                    t = int(f.read().strip())
                                    if t > 0:
                                        return f"{t // 1000}°C"
    except Exception:
        pass

    try:
        thermal_base = "/sys/class/thermal"
        if os.path.exists(thermal_base):
            for zone in os.listdir(thermal_base):
                if zone.startswith("thermal_zone"):
                    zone_path = os.path.join(thermal_base, zone)
                    type_path = os.path.join(zone_path, "type")
                    if os.path.exists(type_path):
                        with open(type_path, "r") as f:
                            ztype = f.read().strip()
                        if ztype in ["x86_pkg_temp", "cpu_thermal", "acpitz"]:
                            temp_path = os.path.join(zone_path, "temp")
                            if os.path.exists(temp_path):
                                with open(temp_path, "r") as f:
                                    t = int(f.read().strip())
                                    if t > 0:
                                        return f"{t // 1000}°C"
    except Exception:
        pass

    temp_files = [
        "/sys/class/thermal/thermal_zone0/temp",
        "/sys/class/thermal/thermal_zone1/temp",
        "/sys/class/hwmon/hwmon0/temp1_input",
        "/sys/class/hwmon/hwmon1/temp1_input",
    ]
    for tf in temp_files:
        if os.path.exists(tf):
            try:
                with open(tf) as f:
                    t = int(f.read().strip())
                    return f"{t // 1000}°C"
            except Exception:
                pass
    return "55°C"


def get_uptime():
    try:
        with open("/proc/uptime") as f:
            uptime_seconds = float(f.read().split()[0])
        hours = int(uptime_seconds // 3600)
        minutes = int((uptime_seconds % 3600) // 60)
        if hours > 0:
            return f"{hours}h {minutes}m"
        else:
            return f"{minutes}m"
    except Exception:
        return "N/A"


def get_cpu_frequency():
    try:
        freq_list = []
        base_path = "/sys/devices/system/cpu"
        for dirname in os.listdir(base_path):
            if dirname.startswith("cpu") and dirname[3:].isdigit():
                freq_file = f"{base_path}/{dirname}/cpufreq/scaling_cur_freq"
                if os.path.exists(freq_file):
                    with open(freq_file, "r") as f:
                        freq_list.append(int(f.read().strip()))
        if freq_list:
            avg_khz = sum(freq_list) / len(freq_list)
            return f"{avg_khz / 1000000.0:.2f} GHz"
    except Exception:
        pass
    return "N/A"


def get_load_average():
    try:
        with open("/proc/loadavg", "r") as f:
            parts = f.read().split()
            return f"{parts[0]} {parts[1]} {parts[2]}"
    except Exception:
        return "0.00 0.00 0.00"


def get_cores_text():
    num_cores = os.cpu_count() or 1
    return f"{num_cores} Cores"


def get_gpu_info():
    global _gpu_name, _gpu_detected, _gpu_checked
    if not _gpu_checked:
        _gpu_checked = True
        try:
            res = subprocess.run(
                ["lspci"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )
            if res.returncode == 0:
                gpus = []
                for line in res.stdout.split("\n"):
                    if any(
                        x in line.lower()
                        for x in ["vga", "3d controller", "display controller"]
                    ):
                        raw_name = None
                        lower_line = line.lower()
                        for keyword in [
                            "vga compatible controller:",
                            "3d controller:",
                            "display controller:",
                        ]:
                            idx = lower_line.find(keyword)
                            if idx != -1:
                                raw_name = line[idx + len(keyword) :].strip()
                                break
                        if not raw_name:
                            parts = line.split(":")
                            if len(parts) >= 3:
                                raw_name = ":".join(parts[2:]).strip()

                        if raw_name:
                            vendor = ""
                            if re.search(r"\bnvidia\b", raw_name.lower()):
                                vendor = "NVIDIA"
                            elif re.search(r"\b(amd|ati)\b", raw_name.lower()):
                                vendor = "AMD"
                            elif re.search(r"\bintel\b", raw_name.lower()):
                                vendor = "Intel"

                            bracket_match = re.search(r"\[([^\]]+)\]", raw_name)
                            if bracket_match:
                                model = bracket_match.group(1).strip()
                                if vendor and not model.lower().startswith(
                                    vendor.lower()
                                ):
                                    name = f"{vendor} {model}"
                                else:
                                    name = model
                            else:
                                name = raw_name
                                name = re.sub(r"\(rev\s+[0-9a-fA-F]+\)", "", name)
                                name = (
                                    name.replace("Corporation", "")
                                    .replace("Technologies", "")
                                    .replace("Inc.", "")
                                    .strip()
                                )
                                name = " ".join(name.split())

                            is_discrete = (
                                "nvidia" in name.lower()
                                or "amd" in name.lower()
                                or "radeon" in name.lower()
                            )
                            gpus.append((is_discrete, name))

                if gpus:
                    gpus.sort(key=lambda x: x[0], reverse=True)
                    _gpu_name = gpus[0][1]
                    _gpu_detected = True
        except Exception:
            pass

    if not _gpu_detected:
        return {
            "has_gpu": False,
            "name": "None",
            "temp": "0°C",
            "usage": 0,
            "vram": "None",
        }

    usage = 0
    temp = "50°C"
    vram = "GPU Active"

    if (
        "nvidia" in _gpu_name.lower()
        or "geforce" in _gpu_name.lower()
        or "rtx" in _gpu_name.lower()
        or "gtx" in _gpu_name.lower()
    ):
        try:
            res = subprocess.run(
                [
                    "nvidia-smi",
                    "--query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total",
                    "--format=csv,noheader,nounits",
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=0.5,
            )
            if res.returncode == 0:
                parts = res.stdout.strip().split(",")
                if len(parts) >= 4:
                    temp = f"{parts[0].strip()}°C"
                    usage = int(parts[1].strip())
                    used_mib = int(parts[2].strip())
                    total_mib = int(parts[3].strip())
                    used_gb = round(used_mib / 1024.0, 1)
                    total_gb = round(total_mib / 1024.0, 1)
                    vram = f"{used_gb} / {total_gb} GB"
                    return {
                        "has_gpu": True,
                        "name": _gpu_name,
                        "temp": temp,
                        "usage": usage,
                        "vram": vram,
                    }
        except Exception:
            pass

    try:
        drm_base = "/sys/class/drm"
        if os.path.exists(drm_base):
            cards = [c for c in os.listdir(drm_base) if c.startswith("card") and "-" not in c]
            for card in cards:
            busy_file = f"/sys/class/drm/{card}/device/gpu_busy_percent"
            if os.path.exists(busy_file):
                with open(busy_file, "r") as f:
                    usage = int(f.read().strip())

                dev_hwmon_dir = f"/sys/class/drm/{card}/device/hwmon"
                if os.path.exists(dev_hwmon_dir):
                    for hwmon in os.listdir(dev_hwmon_dir):
                        tf = f"{dev_hwmon_dir}/{hwmon}/temp1_input"
                        if os.path.exists(tf):
                            with open(tf, "r") as f:
                                t = int(f.read().strip())
                                temp = f"{t // 1000}°C"
                                break

                used_file = f"/sys/class/drm/{card}/device/mem_info_vram_used"
                total_file = f"/sys/class/drm/{card}/device/mem_info_vram_total"
                if os.path.exists(used_file) and os.path.exists(total_file):
                    with open(used_file, "r") as f:
                        vram_used = int(f.read().strip())
                    with open(total_file, "r") as f:
                        vram_total = int(f.read().strip())
                    vram_used_gb = round(vram_used / (1024 * 1024 * 1024), 1)
                    vram_total_gb = round(vram_total / (1024 * 1024 * 1024), 1)
                    vram = f"{vram_used_gb} / {vram_total_gb} GB"
                return {
                    "has_gpu": True,
                    "name": _gpu_name,
                    "temp": temp,
                    "usage": usage,
                    "vram": vram,
                }
    except Exception:
        pass

    return {
        "has_gpu": True,
        "name": _gpu_name,
        "temp": temp,
        "usage": usage,
        "vram": vram,
    }


def get_storage_info():
    try:
        st = os.statvfs("/")
        total_bytes = st.f_blocks * st.f_frsize
        free_bytes = st.f_bfree * st.f_frsize
        used_bytes = total_bytes - free_bytes

        total_gib = round(total_bytes / (1024.0 * 1024.0 * 1024.0), 1)
        used_gib = round(used_bytes / (1024.0 * 1024.0 * 1024.0), 1)
        usage_pct = (
            int(round(100.0 * used_bytes / total_bytes)) if total_bytes > 0 else 0
        )

        dev = "/"
        try:
            with open("/proc/mounts", "r") as f:
                for line in f:
                    parts = line.split()
                    if len(parts) >= 2 and parts[1] == "/":
                        dev = os.path.basename(parts[0])
                        break
        except Exception:
            pass

        return {
            "device": dev,
            "total_gib": total_gib,
            "used_gib": used_gib,
            "usage": usage_pct,
        }
    except Exception:
        return {"device": "/", "total_gib": 0.0, "used_gib": 0.0, "usage": 0}


_music_players_cache = None


def check_music_players():
    global _music_players_cache
    if _music_players_cache is not None:
        return _music_players_cache
    try:
        _music_players_cache = {
            "has_youtube_music": shutil.which("youtube-music") is not None,
            "has_spotify": shutil.which("spotify") is not None,
            "has_kew": shutil.which("kew") is not None,
        }
        return _music_players_cache
    except Exception:
        return {"has_youtube_music": False, "has_spotify": False, "has_kew": False}


def collect_and_output(
    prev_sys_ticks, prev_proc_ticks, sort_by, limit=25, no_processes=False
):
    curr_sys_ticks = get_system_cpu_ticks()
    curr_proc_ticks = {} if no_processes else get_all_processes_ticks()

    sys_cpu_pct = 0.0
    sys_total_diff = curr_sys_ticks["total"] - prev_sys_ticks["total"]
    sys_idle_diff = curr_sys_ticks["idle"] - prev_sys_ticks["idle"]
    if sys_total_diff > 0:
        sys_cpu_pct = round(
            100.0 * (sys_total_diff - sys_idle_diff) / sys_total_diff, 1
        )
        sys_cpu_pct = max(0.0, min(100.0, sys_cpu_pct))

    mem_info = get_system_mem()
    total_mem_bytes = mem_info.get("mem_total_gb", 0) * 1024 * 1024 * 1024
    if total_mem_bytes == 0:
        try:
            with open("/proc/meminfo") as f:
                for line in f:
                    if line.startswith("MemTotal:"):
                        total_mem_bytes = int(line.split()[1]) * 1024
                        break
        except Exception:
            pass

    processes = []
    if not no_processes:
        for pid, curr_p in curr_proc_ticks.items():
            if curr_p["comm"] in ["top", "ps", "get_processes.py", "python3"]:
                continue

            proc_cpu = 0.0
            if pid in prev_proc_ticks:
                prev_p = prev_proc_ticks[pid]
                proc_ticks_diff = (curr_p["utime"] + curr_p["stime"]) - (
                    prev_p["utime"] + prev_p["stime"]
                )
                if sys_total_diff > 0:
                    proc_cpu = round(100.0 * proc_ticks_diff / sys_total_diff, 1)
                    proc_cpu = max(0.0, proc_cpu)

            mem_pct = (
                round(100.0 * curr_p["rss_bytes"] / total_mem_bytes, 1)
                if total_mem_bytes > 0
                else 0.0
            )
            mem_formatted = format_memory(curr_p["rss_bytes"])

            processes.append(
                {
                    "pid": pid,
                    "name": curr_p["comm"],
                    "cpu": proc_cpu,
                    "mem": mem_pct,
                    "mem_str": mem_formatted,
                    "user": get_user_by_uid(curr_p["uid"]),
                    "cmdline": curr_p["cmdline"],
                }
            )

        if sort_by == "cpu":
            processes.sort(key=lambda x: x["cpu"], reverse=True)
        elif sort_by == "mem":
            processes.sort(key=lambda x: x["mem"], reverse=True)
        else:
            processes.sort(key=lambda x: x["cpu"], reverse=True)

    output_data = {
        "system": {
            "cpu_usage": sys_cpu_pct,
            "mem_usage": mem_info["mem_usage"],
            "mem_total_gb": mem_info["mem_total_gb"],
            "mem_used_gb": mem_info["mem_used_gb"],
            "tasks_total": get_system_tasks(),
            "cpu_temp": get_cpu_temp(),
            "uptime": get_uptime(),
            "cpu_freq": get_cpu_frequency(),
            "load_avg": get_load_average(),
            "cpu_cores": get_cores_text(),
        },
        "gpu": get_gpu_info(),
        "storage": get_storage_info(),
        "players": check_music_players(),
        "processes": processes[:limit],
    }

    print(json.dumps(output_data), flush=True)
    return curr_sys_ticks, curr_proc_ticks


if __name__ == "__main__":
    sort_by = "cpu"
    interval = 4.0
    is_daemon = False
    no_processes = False

    for arg in sys.argv[1:]:
        if arg == "--daemon":
            is_daemon = True
        elif arg == "--no-processes":
            no_processes = True
        elif arg in ["cpu", "mem"]:
            sort_by = arg
        else:
            try:
                interval = float(arg) / 1000.0
            except ValueError:
                pass

    if is_daemon:
        prev_sys = get_system_cpu_ticks()
        prev_proc = {} if no_processes else get_all_processes_ticks()
        time.sleep(0.2)
        prev_sys, prev_proc = collect_and_output(
            prev_sys, prev_proc, sort_by, no_processes=no_processes
        )
        while True:
            time.sleep(interval)
            prev_sys, prev_proc = collect_and_output(
                prev_sys, prev_proc, sort_by, no_processes=no_processes
            )
    else:
        prev_sys = get_system_cpu_ticks()
        prev_proc = {} if no_processes else get_all_processes_ticks()
        time.sleep(0.5)
        collect_and_output(prev_sys, prev_proc, sort_by, no_processes=no_processes)
