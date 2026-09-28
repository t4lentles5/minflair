import os
import re
import subprocess

from color_utils import sanitize_color


def apply(home, colors):
    bg = colors["bg"]
    fg = colors["fg"]
    bgSecondary = colors["bgSecondary"]
    accent = colors["accent"]
    accentComplementary = colors["accentComplementary"]
    muted = colors["muted"]
    border = colors["border"]
    shadow = colors["shadow"]
    is_dark = colors["is_dark"]

    mapping = {
        "primary": accent,
        "on_primary": bg,
        "primary_container": bgSecondary,
        "on_primary_container": accent,
        "inverse_primary": bg,
        "primary_fixed": accent,
        "primary_fixed_dim": accent,
        "on_primary_fixed": bg,
        "on_primary_fixed_variant": accent,
        "secondary": fg,
        "on_secondary": bg,
        "secondary_container": bgSecondary,
        "on_secondary_container": fg,
        "secondary_fixed": fg,
        "secondary_fixed_dim": fg,
        "on_secondary_fixed": bg,
        "on_secondary_fixed_variant": fg,
        "tertiary": accentComplementary,
        "on_tertiary": bg,
        "tertiary_container": bgSecondary,
        "on_tertiary_container": accentComplementary,
        "tertiary_fixed": accentComplementary,
        "tertiary_fixed_dim": accentComplementary,
        "on_tertiary_fixed": bg,
        "on_tertiary_fixed_variant": accentComplementary,
        "error": fg,
        "on_error": "#ffffff",
        "error_container": bgSecondary,
        "on_error_container": fg,
        "background": bg,
        "on_background": fg,
        "surface": bg,
        "on_surface": fg,
        "surface_dim": bg,
        "surface_bright": bgSecondary,
        "surface_container_lowest": bg,
        "surface_container_low": bgSecondary,
        "surface_container": bgSecondary,
        "surface_container_high": bgSecondary,
        "surface_container_highest": bgSecondary,
        "surface_variant": bgSecondary,
        "on_surface_variant": muted,
        "surface_tint": bg,
        "outline": border,
        "outline_variant": border,
        "inverse_surface": fg,
        "inverse_on_surface": bg,
        "shadow": shadow,
        "scrim": shadow,
        "source_color": accent,
        "accent": accent,
    }

    gtk4_colors = ":root {\n"
    for k, v in mapping.items():
        gtk4_colors += f"  --{k}: {sanitize_color(v)};\n"
    gtk4_colors += "}\n\nselection,\n:selected {\n  background-color: var(--accent);\n  color: var(--bg);\n}\n"
    gtk4_colors += "\n.background,\niconview:not(:selected),\n.view:not(:selected) {\n  color: var(--on_surface);\n}\n"

    gtk3_colors = ""
    for k, v in mapping.items():
        gtk3_colors += f"@define-color {k} {sanitize_color(v)};\n"
    gtk3_colors += (
        "\nselection,\n:selected {\n  background-color: @accent;\n  color: @bg;\n}\n"
    )
    gtk3_colors += "\n.background,\niconview:not(:selected),\n.view:not(:selected) {\n  color: @on_surface;\n}\n"

    theme_dir = os.path.join(home, ".themes", "Material-Gnome")
    os.makedirs(os.path.join(theme_dir, "gtk-3.0"), exist_ok=True)
    os.makedirs(os.path.join(theme_dir, "gtk-4.0"), exist_ok=True)
    os.makedirs(os.path.join(home, ".config", "gtk-3.0"), exist_ok=True)
    os.makedirs(os.path.join(home, ".config", "gtk-4.0"), exist_ok=True)

    with open(os.path.join(theme_dir, "gtk-4.0", "colors.css"), "w") as f:
        f.write(gtk4_colors)
    with open(os.path.join(theme_dir, "gtk-3.0", "colors.css"), "w") as f:
        f.write(gtk3_colors)

    def safe_symlink(src, dst):
        try:
            if os.path.islink(dst) or os.path.exists(dst):
                os.remove(dst)
            os.symlink(src, dst)
        except OSError:
            pass

    def safe_touch(path):
        try:
            with open(path, "a"):
                pass
        except OSError:
            pass

    safe_touch(os.path.join(theme_dir, "gtk-3.0", "gtk.css"))
    safe_touch(os.path.join(theme_dir, "gtk-3.0", "gtk-dark.css"))
    safe_touch(os.path.join(home, ".config", "gtk-4.0", "gtk.css"))
    safe_touch(os.path.join(home, ".config", "gtk-4.0", "gtk-dark.css"))

    safe_symlink(
        os.path.join(theme_dir, "gtk-3.0", "gtk.css"),
        os.path.join(home, ".config", "gtk-3.0", "gtk.css"),
    )
    safe_symlink(
        os.path.join(theme_dir, "gtk-3.0", "colors.css"),
        os.path.join(home, ".config", "gtk-3.0", "colors.css"),
    )
    safe_symlink(
        os.path.join(theme_dir, "gtk-4.0", "gtk.css"),
        os.path.join(home, ".config", "gtk-4.0", "gtk.css"),
    )
    safe_symlink(
        os.path.join(theme_dir, "gtk-4.0", "gtk-dark.css"),
        os.path.join(home, ".config", "gtk-4.0", "gtk-dark.css"),
    )
    safe_symlink(
        os.path.join(theme_dir, "gtk-4.0", "colors.css"),
        os.path.join(home, ".config", "gtk-4.0", "colors.css"),
    )

    gs_val = "prefer-dark" if is_dark else "prefer-light"
    opp_val = "prefer-light" if is_dark else "prefer-dark"

    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", opp_val],
        stderr=subprocess.DEVNULL,
    )
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", gs_val],
        stderr=subprocess.DEVNULL,
    )
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", "Adwaita"],
        stderr=subprocess.DEVNULL,
    )
    subprocess.run(
        [
            "gsettings",
            "set",
            "org.gnome.desktop.interface",
            "gtk-theme",
            "Material-Gnome",
        ],
        stderr=subprocess.DEVNULL,
    )

    for ini in [
        os.path.join(home, ".config", "gtk-3.0", "settings.ini"),
        os.path.join(home, ".config", "gtk-4.0", "settings.ini"),
    ]:
        if os.path.exists(ini):
            try:
                with open(ini, "r") as f:
                    content = f.read()
                content = re.sub(
                    r"^gtk-theme-name=.*",
                    "gtk-theme-name=Material-Gnome",
                    content,
                    flags=re.MULTILINE,
                )
                with open(ini, "w") as f:
                    f.write(content)
            except Exception:
                pass
    os.system(
        f"sed -i 's/^Net\/ThemeName.*/Net\/ThemeName \"Material-Gnome\"/' '{home}/.config/xsettingsd/xsettingsd.conf' 2>/dev/null"
    )
    os.system("killall -HUP xsettingsd 2>/dev/null || true")
