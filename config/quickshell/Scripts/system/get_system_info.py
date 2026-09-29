#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import json
import os
import platform
import re
import subprocess
from pathlib import Path


def clean_brand_name(text: str) -> str:
    """Removes annoying OEM and trademark suffixes."""
    if not text:
        return ""
    text = re.sub(
        r"\(R\)|\(TM\)|Corporation|Inc\.|Co\.,?\s*Ltd\.?",
        "",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(r"\s+", " ", text).strip()
    return text


def get_host_model() -> str:
    """Detects laptop model, desktop motherboard, or ARM device-tree model."""
    # 1. Check ARM / Apple Silicon device tree
    for dt_path in ["/proc/device-tree/model", "/sys/firmware/devicetree/base/model"]:
        if os.path.exists(dt_path):
            try:
                with open(dt_path, "rb") as f:
                    model = (
                        f.read()
                        .decode("utf-8", errors="ignore")
                        .replace("\x00", "")
                        .strip()
                    )
                    if model:
                        return model
            except Exception:
                pass

    # 2. Check DMI Dirs for Laptop / Desktop info
    dmi_dirs = ["/sys/devices/virtual/dmi/id", "/sys/class/dmi/id"]
    sys_vendor = ""
    product_name = ""
    product_version = ""
    board_name = ""
    board_vendor = ""

    invalid_names = {
        "none",
        "to be filled by o.e.m.",
        "system product name",
        "system version",
        "default string",
        "not applicable",
        "undefined",
        "type2 - board version",
    }

    for dmi in dmi_dirs:
        if os.path.exists(dmi):

            def read_dmi(name):
                try:
                    p = os.path.join(dmi, name)
                    if os.path.exists(p):
                        with open(p, "r", encoding="utf-8", errors="ignore") as f:
                            val = f.read().strip()
                            return val if val.lower() not in invalid_names else ""
                except Exception:
                    pass
                return ""

            sys_vendor = read_dmi("sys_vendor")
            product_name = read_dmi("product_name")
            product_version = read_dmi("product_version")
            board_name = read_dmi("board_name")
            board_vendor = read_dmi("board_vendor")
            break

    # Prioritize product name (Laptops / Prebuilts)
    if product_name:
        if sys_vendor and not product_name.lower().startswith(sys_vendor.lower()):
            # e.g. "Acer" + "Nitro AN515-57"
            clean_vendor = clean_brand_name(sys_vendor)
            return f"{clean_vendor} {product_name}".strip()
        return product_name

    # Fallback to motherboard name (Custom Desktop PCs)
    if board_name:
        vendor = board_vendor or sys_vendor
        if vendor and not board_name.lower().startswith(vendor.lower()):
            return f"{clean_brand_name(vendor)} {board_name}".strip()
        return board_name

    if product_version:
        return product_version

    return platform.node()


def get_cpu_info() -> tuple[str, str]:
    """Detects CPU Model and Physical Cores / Logical Threads across Intel, AMD, ARM."""
    cpu_model = ""
    physical_cores = 0
    threads = os.cpu_count() or 1

    # 1. Parse /proc/cpuinfo
    core_ids = set()
    try:
        with open("/proc/cpuinfo", "r", encoding="utf-8", errors="ignore") as f:
            curr_phys_id = 0
            for line in f:
                line_str = line.strip()
                if not cpu_model:
                    if (
                        line_str.startswith("model name")
                        or line_str.startswith("Processor")
                        or line_str.startswith("Model")
                    ):
                        parts = line_str.split(":", 1)
                        if len(parts) > 1:
                            cpu_model = parts[1].strip()
                    elif line_str.startswith("Hardware"):
                        parts = line_str.split(":", 1)
                        if len(parts) > 1:
                            cpu_model = parts[1].strip()

                if line_str.startswith("physical id"):
                    try:
                        curr_phys_id = int(line_str.split(":", 1)[1].strip())
                    except ValueError:
                        pass
                elif line_str.startswith("core id"):
                    try:
                        c_id = int(line_str.split(":", 1)[1].strip())
                        core_ids.add((curr_phys_id, c_id))
                    except ValueError:
                        pass
                elif line_str.startswith("cpu cores") and physical_cores == 0:
                    try:
                        physical_cores = int(line_str.split(":", 1)[1].strip())
                    except ValueError:
                        pass
    except Exception:
        pass

    if core_ids:
        physical_cores = len(core_ids)

    # 2. Fallback to lscpu if cpu_model is still empty or generic
    if not cpu_model or cpu_model.lower() in ["unknown", "arm"]:
        try:
            lscpu_out = subprocess.check_output(
                ["lscpu"], text=True, stderr=subprocess.DEVNULL
            )
            for l in lscpu_out.splitlines():
                if "Model name:" in l and not cpu_model:
                    cpu_model = l.split(":", 1)[1].strip()
                elif "Core(s) per socket:" in l and physical_cores == 0:
                    try:
                        physical_cores = int(l.split(":", 1)[1].strip())
                    except ValueError:
                        pass
        except Exception:
            pass

    if not cpu_model:
        cpu_model = platform.processor() or "Generic CPU"

    # Clean CPU formatting
    cpu_model = clean_brand_name(cpu_model)
    cpu_model = re.sub(r"\s+", " ", cpu_model).strip()

    if physical_cores > 0 and physical_cores != threads:
        cores_text = f"{physical_cores} Cores, {threads} Threads"
    elif physical_cores > 0:
        cores_text = f"{physical_cores} Cores"
    else:
        cores_text = f"{threads} Threads"

    return cpu_model, cores_text


def get_gpus() -> str:
    """Detects GPUs from NVIDIA, AMD, Intel, Apple, ARM SoC, or VMs."""
    gpus = []

    # 1. Scan PCI devices
    try:
        res = subprocess.run(["lspci"], capture_output=True, text=True, errors="ignore")
        if res.returncode == 0:
            for line in res.stdout.splitlines():
                if any(
                    k in line.lower()
                    for k in [
                        "vga compatible controller",
                        "3d controller",
                        "display controller",
                    ]
                ):
                    parts = line.split(":", 2)
                    if len(parts) >= 3:
                        raw_name = parts[2].strip()
                        raw_name = re.sub(r"\(rev [0-9a-fA-F]+\)", "", raw_name).strip()

                        # Detect vendor
                        vendor = ""
                        if "nvidia" in raw_name.lower():
                            vendor = "NVIDIA"
                        elif (
                            "amd" in raw_name.lower()
                            or "advanced micro devices" in raw_name.lower()
                        ):
                            vendor = "AMD"
                        elif "intel" in raw_name.lower():
                            vendor = "Intel"

                        # Extract bracketed marketing name [GeForce RTX ...], [Radeon ...]
                        m = re.search(r"\[([^\]]+)\]", raw_name)
                        if m:
                            clean_name = m.group(1).strip()
                            if vendor and not clean_name.lower().startswith(
                                vendor.lower()
                            ):
                                gpus.append(f"{vendor} {clean_name}")
                            else:
                                gpus.append(clean_name)
                        else:
                            clean_raw = clean_brand_name(raw_name)
                            clean_raw = re.sub(
                                r"^(VGA compatible controller|3D controller|Display controller):\s*",
                                "",
                                clean_raw,
                                flags=re.IGNORECASE,
                            )
                            gpus.append(clean_raw)
    except Exception:
        pass

    # 2. DRM Card fallback (For Apple Silicon, ARM, Raspberry Pi, VMs)
    if not gpus and os.path.exists("/sys/class/drm"):
        try:
            for card in sorted(os.listdir("/sys/class/drm")):
                if card.startswith("card") and "-" not in card:
                    dev_path = f"/sys/class/drm/{card}/device"
                    driver_link = os.path.join(dev_path, "driver")
                    if os.path.islink(driver_link):
                        driver = os.path.basename(os.readlink(driver_link))
                        driver_map = {
                            "asahi": "Apple Silicon GPU",
                            "v3d": "Broadcom VideoCore VI",
                            "vc4": "Broadcom VideoCore IV",
                            "panfrost": "ARM Mali GPU",
                            "msm": "Qualcomm Adreno",
                            "virtio-gpu": "VirtIO GPU",
                            "vmwgfx": "VMware SVGA3D",
                            "qxl": "QXL Virtual GPU",
                            "nouveau": "NVIDIA (Nouveau)",
                            "amdgpu": "AMD Radeon Graphics",
                            "i915": "Intel HD/UHD Graphics",
                            "xe": "Intel Arc / Xe Graphics",
                        }
                        name = driver_map.get(driver, f"{driver.capitalize()} Graphics")
                        if name not in gpus:
                            gpus.append(name)
        except Exception:
            pass

    return " | ".join(gpus) if gpus else "Integrated Graphics"


def get_displays() -> str:
    """Detects active display resolutions and refresh rates from Hyprland or DRM."""
    displays = []
    # 1. Hyprland monitors
    try:
        mon_proc = subprocess.run(
            ["hyprctl", "monitors", "-j"],
            capture_output=True,
            text=True,
            errors="ignore",
        )
        if mon_proc.returncode == 0:
            mons = json.loads(mon_proc.stdout)
            for m in mons:
                w = m.get("width", 0)
                h = m.get("height", 0)
                rr = int(m.get("refreshRate", 60))
                model = m.get("model", "").strip()
                name = m.get("name", "")
                label = model if (model and model.lower() != "unknown") else name
                if label:
                    displays.append(f"{label} ({w}x{h} @ {rr}Hz)")
                else:
                    displays.append(f"{w}x{h} @ {rr}Hz")
    except Exception:
        pass

    if displays:
        return ", ".join(displays)

    # 2. DRM connector modes fallback
    if os.path.exists("/sys/class/drm"):
        try:
            for conn in sorted(os.listdir("/sys/class/drm")):
                status_path = f"/sys/class/drm/{conn}/status"
                modes_path = f"/sys/class/drm/{conn}/modes"
                if os.path.exists(status_path) and os.path.exists(modes_path):
                    with open(status_path) as sf:
                        if sf.read().strip() == "connected":
                            with open(modes_path) as mf:
                                first_mode = mf.readline().strip()
                                if first_mode:
                                    clean_conn = conn.replace("card0-", "").replace(
                                        "card1-", ""
                                    )
                                    displays.append(f"{clean_conn}: {first_mode}")
        except Exception:
            pass

    return ", ".join(displays) if displays else "1920x1080 @ 60Hz"


def get_system_specs():
    data = {}

    # OS Name and Architecture
    os_name = "Linux"
    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    os_name = line.split("=", 1)[1].strip().strip('"')
                    break
    except Exception:
        pass
    arch = platform.machine()
    data["os"] = f"{os_name} {arch}".strip()

    # Host / Laptop / Desktop model
    data["host"] = get_host_model()

    # Kernel & Hostname
    data["kernel"] = platform.release()
    data["hostname"] = platform.node()
    data["username"] = os.environ.get("USER", os.environ.get("LOGNAME", ""))

    # Shell
    shell_env = os.environ.get("SHELL", "")
    data["shell"] = Path(shell_env).name if shell_env else "zsh"

    # Window Manager / Compositor
    data["wm"] = "Hyprland (Wayland)"

    # Installed Packages Count
    n_pacman = 0
    n_aur = 0
    try:
        n_pacman = int(
            subprocess.check_output("pacman -Qn 2>/dev/null | wc -l", shell=True)
            .decode()
            .strip()
        )
        n_aur = int(
            subprocess.check_output("pacman -Qm 2>/dev/null | wc -l", shell=True)
            .decode()
            .strip()
        )
    except Exception:
        pass
    data["packages"] = (
        f"{n_pacman} (pacman), {n_aur} (aur)" if n_aur > 0 else f"{n_pacman} (pacman)"
    )

    # Displays
    data["display"] = get_displays()

    # CPU & Cores
    cpu_model, cpu_cores = get_cpu_info()
    data["cpu_model"] = cpu_model
    data["cpu_cores"] = cpu_cores

    # Total RAM
    ram_gb = "0 GB"
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if "MemTotal" in line:
                    kb = int(line.split()[1])
                    ram_gb = f"{kb / (1024 * 1024):.1f} GB"
                    break
    except Exception:
        pass
    data["ram_total"] = ram_gb

    # Root Storage Total
    disk_total = ""
    try:
        st = os.statvfs("/")
        total_b = st.f_blocks * st.f_frsize
        disk_total = f"{total_b / (1024**3):.0f} GB"
    except Exception:
        pass
    data["disk_total"] = disk_total

    # GPUs
    data["gpus"] = get_gpus()

    return data


if __name__ == "__main__":
    print(json.dumps(get_system_specs()))
