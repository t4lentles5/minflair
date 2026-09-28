import configparser
import os

from color_utils import sanitize_color


def apply(home, colors):
    bg = colors["bg"]
    fg = colors["fg"]
    bgSecondary = colors["bgSecondary"]
    accent = colors["accent"]
    accentComplementary = colors["accentComplementary"]
    muted = colors["muted"]
    shadow = colors["shadow"]
    is_dark = colors["is_dark"]

    def to_argb(c, alpha="ff"):
        s = sanitize_color(c)
        if len(s) == 7:
            return f"#{alpha}{s[1:]}"
        return s

    qt_colors = [
        to_argb(fg),
        to_argb(bgSecondary),
        to_argb(muted),
        to_argb(muted),
        to_argb(bgSecondary),
        to_argb(bgSecondary),
        to_argb(fg),
        to_argb(fg),
        to_argb(fg),
        to_argb(bg),
        to_argb(bg),
        to_argb(shadow),
        to_argb(accent),
        to_argb(bg),
        to_argb(accent),
        to_argb(accentComplementary),
        to_argb(bgSecondary),
        "#ffffffff",
        to_argb(bgSecondary),
        to_argb(fg),
        to_argb(muted, "80"),
    ]

    qt_colors_str = ", ".join(qt_colors)
    qt_conf_content = f"[ColorScheme]\nactive_colors={qt_colors_str}\ninactive_colors={qt_colors_str}\ndisabled_colors={qt_colors_str}\n"

    for qtct in ["qt5ct", "qt6ct"]:
        qt_dir = os.path.join(home, ".config", qtct, "colors")
        os.makedirs(qt_dir, exist_ok=True)
        scheme_path = os.path.join(qt_dir, "quickshell.conf")
        with open(scheme_path, "w") as f2:
            f2.write(qt_conf_content)

        qtct_conf = os.path.join(home, ".config", qtct, f"{qtct}.conf")
        if os.path.exists(qtct_conf):
            config = configparser.ConfigParser()
            config.optionxform = str
            config.read(qtct_conf)
            if "Appearance" not in config:
                config["Appearance"] = {}
            config["Appearance"]["color_scheme_path"] = scheme_path
            config["Appearance"]["custom_palette"] = "true"
            icon_theme = "Papirus-Dark" if is_dark else "Papirus-Light"
            config["Appearance"]["icon_theme"] = icon_theme
            with open(qtct_conf, "w") as configfile:
                config.write(configfile)
