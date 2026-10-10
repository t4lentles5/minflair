#!/usr/bin/env bash

# Multi-vendor Linux battery charge limit controller
# Supports:
# - Standard Linux kernel 5.4+ charge_control_end_threshold (ASUS, ThinkPad, Framework, Apple T2/Silicon, System76, LG, Sony, etc.)
# - Lenovo IdeaPad (conservation_mode)
# - Acer (health_mode / acer-wmi-battery)
# - LG Gram (battery_care_limit)
# - Samsung (battery_life_extender)
# - Sony Vaio (battery_care_limiter)
# - Huawei MateBook (charge_thresholds)

detect_interface() {
  # 1. Standard Kernel sysfs charge_control_end_threshold (ASUS, ThinkPad, Framework, Apple, etc.)
  for f in /sys/class/power_supply/BAT*/charge_control_end_threshold \
    /sys/class/power_supply/macsmc-battery/charge_control_end_threshold \
    /sys/devices/platform/asus-nb-wmi/charge_control_end_threshold; do
    if [ -f "$f" ]; then
      echo "standard_threshold:$f"
      return 0
    fi
  done

  # 2. Lenovo IdeaPad conservation_mode
  for f in /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode \
    /sys/bus/platform/drivers/ideapad_laptop/VPC2004:00/conservation_mode \
    /sys/devices/platform/ideapad_acpi/conservation_mode \
    /sys/devices/platform/ideapad/conservation_mode; do
    if [ -f "$f" ]; then
      echo "binary_mode:$f"
      return 0
    fi
  done

  # 3. Acer health_mode
  for f in /sys/bus/wmi/drivers/acer-wmi-battery/health_mode \
    /sys/devices/platform/acer-wmi/health_mode; do
    if [ -f "$f" ]; then
      echo "binary_mode:$f"
      return 0
    fi
  done

  # 4. LG Gram battery_care_limit
  for f in /sys/devices/platform/lg-laptop/battery_care_limit; do
    if [ -f "$f" ]; then
      echo "lg_limit:$f"
      return 0
    fi
  done

  # 5. Samsung battery_life_extender
  for f in /sys/devices/platform/samsung/battery_life_extender; do
    if [ -f "$f" ]; then
      echo "binary_mode:$f"
      return 0
    fi
  done

  # 6. Sony Vaio battery_care_limiter
  for f in /sys/devices/platform/sony-laptop/battery_care_limiter; do
    if [ -f "$f" ]; then
      echo "sony_limit:$f"
      return 0
    fi
  done

  # 7. Huawei charge_thresholds
  for f in /sys/devices/platform/huawei-wmi/charge_thresholds \
    /sys/bus/platform/drivers/huawei-wmi/charge_thresholds; do
    if [ -f "$f" ]; then
      echo "huawei_threshold:$f"
      return 0
    fi
  done

  echo "unsupported"
  return 1
}

IFACE_INFO=$(detect_interface)

if [ "$IFACE_INFO" = "unsupported" ]; then
  if [ "$1" = "status" ]; then
    echo "unsupported"
    exit 0
  else
    echo "ERROR: Battery limit control is not supported on this hardware." >&2
    exit 1
  fi
fi

TYPE="${IFACE_INFO%%:*}"
TARGET_FILE="${IFACE_INFO#*:}"
ACTION="${1:-status}"

get_status() {
  case "$TYPE" in
  "standard_threshold")
    val=$(cat "$TARGET_FILE" 2>/dev/null)
    if [ -n "$val" ] && [ "$val" -lt 100 ] && [ "$val" -gt 0 ]; then
      echo "1"
    else
      echo "0"
    fi
    ;;
  "binary_mode")
    val=$(cat "$TARGET_FILE" 2>/dev/null)
    if [ "$val" = "1" ]; then
      echo "1"
    else
      echo "0"
    fi
    ;;
  "lg_limit")
    val=$(cat "$TARGET_FILE" 2>/dev/null)
    if [ "$val" = "80" ]; then
      echo "1"
    else
      echo "0"
    fi
    ;;
  "sony_limit")
    val=$(cat "$TARGET_FILE" 2>/dev/null)
    if [ -n "$val" ] && [ "$val" -gt 0 ]; then
      echo "1"
    else
      echo "0"
    fi
    ;;
  "huawei_threshold")
    val=$(cat "$TARGET_FILE" 2>/dev/null)
    end=$(echo "$val" | awk '{print $2}')
    if [ -n "$end" ] && [ "$end" -lt 100 ] && [ "$end" -gt 0 ]; then
      echo "1"
    else
      echo "0"
    fi
    ;;
  *)
    echo "unsupported"
    ;;
  esac
}

write_value() {
  local new_val="$1"
  if [ -w "$TARGET_FILE" ]; then
    echo "$new_val" >"$TARGET_FILE"
  elif command -v pkexec >/dev/null 2>&1 && [ -z "$SUDO_USER" ] && [ "$EUID" -ne 0 ]; then
    sh -c "echo '$new_val' > '$TARGET_FILE'" 2>/dev/null || pkexec sh -c "echo '$new_val' > '$TARGET_FILE'"
  else
    echo "$new_val" >"$TARGET_FILE"
  fi
}

toggle_limit() {
  local curr
  curr=$(get_status)

  case "$TYPE" in
  "standard_threshold")
    if [ "$curr" = "1" ]; then
      write_value "100"
      echo "0"
    else
      write_value "80"
      echo "1"
    fi
    ;;
  "binary_mode")
    if [ "$curr" = "1" ]; then
      write_value "0"
      echo "0"
    else
      write_value "1"
      echo "1"
    fi
    ;;
  "lg_limit")
    if [ "$curr" = "1" ]; then
      write_value "100"
      echo "0"
    else
      write_value "80"
      echo "1"
    fi
    ;;
  "sony_limit")
    if [ "$curr" = "1" ]; then
      write_value "0"
      echo "0"
    else
      write_value "80"
      echo "1"
    fi
    ;;
  "huawei_threshold")
    if [ "$curr" = "1" ]; then
      write_value "0 100"
      echo "0"
    else
      write_value "40 80"
      echo "1"
    fi
    ;;
  esac
}

if [ "$ACTION" = "status" ]; then
  get_status
elif [ "$ACTION" = "toggle" ]; then
  toggle_limit
elif [ "$ACTION" = "info" ]; then
  echo "Interface: $TYPE"
  echo "Target: $TARGET_FILE"
  echo "Status: $(get_status)"
else
  echo "Usage: $0 {status|toggle|info}"
  exit 1
fi
