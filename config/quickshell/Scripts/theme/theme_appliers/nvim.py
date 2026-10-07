import os
import stat
import subprocess

from color_utils import sanitize_color


def apply(home, colors):
    bg = colors["bg"]
    fg = colors["fg"]
    bgSecondary = colors["bgSecondary"]
    bgTertiary = colors.get("bgTertiary", bgSecondary)
    bgAccent = colors.get("bgAccent", colors["accent"])
    bgAccentComplementary = colors.get(
        "bgAccentComplementary", colors["accentComplementary"]
    )
    overlayBase = colors.get("overlayBase", colors["accent"])
    accent = colors["accent"]
    accentComplementary = colors["accentComplementary"]
    muted = colors["muted"]
    border = colors.get("border", muted)
    is_dark = colors["is_dark"]

    nvim_bg = "dark" if is_dark else "light"
    qs_colors = f"""vim.g.qs_colors = {{
  bg = "{sanitize_color(bg)}",
  bgSecondary = "{sanitize_color(bgSecondary)}",
  bgTertiary = "{sanitize_color(bgTertiary)}",
  bgAccent = "{sanitize_color(bgAccent)}",
  bgAccentComplementary = "{sanitize_color(bgAccentComplementary)}",
  overlayBase = "{sanitize_color(overlayBase)}",
  fg = "{sanitize_color(fg)}",
  muted = "{sanitize_color(muted)}",
  border = "{sanitize_color(border)}",
  accent = "{sanitize_color(accent)}",
  accentComplementary = "{sanitize_color(accentComplementary)}",
  surface = "{sanitize_color(bgSecondary)}",
  bg_alt = "{sanitize_color(bgTertiary)}",
  selection = "{sanitize_color(bgAccent)}",
  float_border = "{sanitize_color(border)}",
  comment = "{sanitize_color(muted)}",
  func = "{sanitize_color(accent)}",
  keyword = "{sanitize_color(accentComplementary)}",
  type = "{sanitize_color(accentComplementary)}",
}}
"""
    lua_content = f'vim.opt.background = "{nvim_bg}"\n{qs_colors}for k in pairs(package.loaded) do if k == "luna" or k:match("^luna%.") then package.loaded[k] = nil end end\npcall(vim.cmd.colorscheme, "luna")'
    nvim_theme_file = os.path.join(home, ".cache", "quickshell", "nvim_theme.lua")
    os.makedirs(os.path.dirname(nvim_theme_file), exist_ok=True)
    with open(nvim_theme_file, "w") as f2:
        f2.write(lua_content)

    try:
        for d in ["/tmp", os.environ.get("XDG_RUNTIME_DIR", "")]:
            if not d or not os.path.isdir(d):
                continue
            for f_name in os.listdir(d):
                if f_name.startswith("nvim."):
                    path = os.path.join(d, f_name)
                    socket_path = None
                    if os.path.isdir(path):
                        s = os.path.join(path, "0")
                        if os.path.exists(s) and stat.S_ISSOCK(os.stat(s).st_mode):
                            socket_path = s
                    elif stat.S_ISSOCK(os.stat(path).st_mode):
                        socket_path = path

                    if socket_path:
                        subprocess.run(
                            [
                                "nvim",
                                "--server",
                                socket_path,
                                "--remote-expr",
                                f'execute("source {nvim_theme_file}")',
                            ],
                            stderr=subprocess.DEVNULL,
                            stdout=subprocess.DEVNULL,
                        )
    except Exception:
        pass
