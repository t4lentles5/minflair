import os
import subprocess

from color_utils import sanitize_color


def apply(home, colors):
    bg = colors["bg"]
    fg = colors["fg"]
    accent = colors["accent"]
    accentComplementary = colors["accentComplementary"]
    muted = colors["muted"]
    border = colors["border"]
    bgSecondary = colors["bgSecondary"]
    bgTertiary = colors.get("bgTertiary", bgSecondary)
    bgAccent = colors.get("bgAccent", accent)
    bgAccentComplementary = colors.get("bgAccentComplementary", accentComplementary)
    overlayBase = colors.get("overlayBase", accent)

    kitty_theme = f"""foreground              {sanitize_color(fg)}
background              {sanitize_color(bg)}
selection_foreground    {sanitize_color(bg)}
selection_background    {sanitize_color(accent)}
cursor                  {sanitize_color(fg)}
cursor_text_color       {sanitize_color(bg)}
url_color               {sanitize_color(accentComplementary)}
active_border_color     {sanitize_color(accent)}
inactive_border_color   {sanitize_color(border)}
bell_border_color       {sanitize_color(accentComplementary)}
active_tab_foreground   {sanitize_color(bg)}
active_tab_background   {sanitize_color(accent)}
inactive_tab_foreground {sanitize_color(muted)}
inactive_tab_background {sanitize_color(bgSecondary)}
tab_bar_background      {sanitize_color(bg)}
color0  {sanitize_color(accent)}
color8  {sanitize_color(accent)}
color1  {sanitize_color(accent)}
color9  {sanitize_color(accent)}
color2  {sanitize_color(accent)}
color10 {sanitize_color(accent)}
color3  {sanitize_color(accent)}
color11 {sanitize_color(accent)}
color4  {sanitize_color(accent)}
color12 {sanitize_color(accent)}
color5  {sanitize_color(accent)}
color13 {sanitize_color(accent)}
color6  {sanitize_color(accent)}
color14 {sanitize_color(accent)}
color7  {sanitize_color(accent)}
color15 {sanitize_color(accent)}
color16 {sanitize_color(accent)}
color17 {sanitize_color(accent)}
color18 {sanitize_color(accent)}
color19 {sanitize_color(accent)}
color20 {sanitize_color(accent)}
color21 {sanitize_color(accent)}
"""
    kitty_dir = os.path.join(home, ".config", "kitty")
    os.makedirs(kitty_dir, exist_ok=True)
    with open(os.path.join(kitty_dir, "theme.conf"), "w") as f2:
        f2.write(kitty_theme)
    subprocess.run("kill -SIGUSR1 $(pidof kitty) 2>/dev/null", shell=True)
