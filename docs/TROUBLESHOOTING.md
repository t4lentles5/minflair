# Troubleshooting

## Inspect Quickshell logs or debug UI issues

If any widget is not showing up or an error occurs in the UI, view live
Quickshell logs in your terminal:

```bash
qs log
```

This prints real-time QML errors, warnings, missing components and script
failures.

## Battery charge limit toggle not working

Ensure your laptop vendor supports charging thresholds via the Linux kernel.
Check if your vendor's kernel module is loaded (for example `asus_wmi`,
`ideapad_laptop` or `thinkpad_acpi`). For Acer laptops, the installer
automatically configures `acer-wmi-battery-dkms`.

## Brightness slider has no effect on an external monitor

Internal panels use `brightnessctl`, while external monitors use DDC/CI through
`ddcutil`. The installer sets this up, but group membership requires a new
session. If needed, run it manually and log out afterwards:

```bash
sudo pacman -S ddcutil
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf
sudo modprobe i2c-dev
sudo usermod -aG i2c "$USER"
```

Check the detected backend and whether the monitor exposes DDC/CI:

```bash
~/.config/quickshell/Scripts/system/brightness.sh backend
ddcutil detect
```

Some monitors ship with DDC/CI disabled in their OSD menu; enable it there.
When nothing is detected, Minflair waits 30 seconds before retrying, so give it
a moment after connecting a display.

## Avatar (`.face`) not showing on SDDM or the Quickshell dashboard

Place a square image at `~/.face` (PNG or JPG). The dashboard and SDDM read it
from `$HOME/.face`.

If the avatar shows in test mode (`sddm-greeter --test-mode`) but not on the
actual SDDM login screen, the `sddm` system user is blocked by restricted home
directory permissions (`700`). Fix it by running:

```bash
setfacl -m u:sddm:x "$HOME"
setfacl -m u:sddm:r "$HOME/.face"
```

## No wallpapers appear in the wallpaper selector

Place your own wallpapers in `~/Pictures/Wallpapers/`. Create the directory if
it does not exist and add your images there.

## GTK apps do not follow the theme change

Nautilus is automatically restarted when switching between light and dark mode.
For other GTK apps, close and reopen them. The `nwg-look` tool is used during
installation to apply the initial GTK settings.

## Notifications are not showing

The installer disables `dunst` because Quickshell handles notifications
natively. If you installed another notification daemon, it may conflict. Check
with:

```bash
systemctl --user status dunst.service
```

## Installation errors or packages failed to install

The installer captures warnings and errors in a log file:

```bash
cat ~/install_errors.log
```

If packages failed to install, make sure your mirrors are up to date
(`sudo pacman -Syy`) and that your AUR helper works (`yay -Syu`).
