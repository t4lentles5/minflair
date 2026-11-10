# Post-installation setup

After `./install.sh` finishes, complete these steps.

## 1. Reboot

Reboot so all services, themes and shell environments take effect:

```bash
sudo reboot
```

## 2. Set your profile picture (`.face`)

To display your personal avatar on the dashboard, lock screen and SDDM login
screen, place a square image (`PNG` or `JPG`) at `~/.face`:

```bash
cp /path/to/your/avatar.png ~/.face
```

SDDM runs under its own system user (`sddm`). Because user home directories
default to `700` (`drwx------`) permissions on Linux, grant SDDM traversal and
read access via ACL so the avatar appears on the login screen:

```bash
setfacl -m u:sddm:x "$HOME"
setfacl -m u:sddm:r "$HOME/.face"
```

## 3. Add your wallpapers

Wallpapers are stored in `~/Pictures/Wallpapers/`. Add your favorite images
there and use the wallpaper selector (`Ctrl + Alt + W`) to switch between them
instantly.

## 4. Monitor configuration

Displays are configured to auto-detect by default. If you need a custom
resolution, refresh rate or multi-monitor arrangement, configure:

```bash
~/.config/hypr/monitors.lua
```

## 5. Restore from backup

The installer preserves a timestamped backup of your previous configuration at:

```text
~/.minflair_backup/<timestamp>/
```

Backups created by older versions remain in `~/.dotfiles_backup/<timestamp>/`.

## 6. OCR text extraction languages

The screen capture OCR feature comes with English and Spanish language packs
preinstalled. To add other languages (such as French, German or Japanese),
install the corresponding package:

```bash
# Example for French
sudo pacman -S tesseract-data-fra
```

## 7. Battery charge limit (laptops)

The Control Center includes an 80% charge limit toggle to prolong battery
lifespan. The installer automatically detects your hardware and configures
support for major laptop brands (ASUS, Lenovo, Dell, Acer, Apple Silicon,
Framework, HP and others).

## 8. Brightness on external monitors (DDC/CI)

Internal laptop panels are controlled with `brightnessctl` out of the box.
External monitors are controlled over DDC/CI with `ddcutil`, which the
installer installs and configures: the `i2c-dev` module is loaded on boot and
your user is added to the `i2c` group.

The group change only takes effect after logging out and back in (the installer
already asks you to reboot). To check which backend is active at any time:

```bash
~/.config/quickshell/Scripts/system/brightness.sh backend
```

It prints `brightnessctl` for an internal panel, `ddcutil` for external
monitors, or `none` when no supported display is found. On a laptop, the
internal panel always takes priority over connected external monitors.
