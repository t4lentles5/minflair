import os
import subprocess

from color_utils import sanitize_color


def apply(home, colors):
    bg = colors["bg"]
    fg = colors["fg"]
    accent = colors["accent"]
    muted = colors["muted"]
    bgSecondary = colors["bgSecondary"]

    kitty_theme = f"""foreground              {sanitize_color(fg)}
background              {sanitize_color(bg)}
selection_foreground    {sanitize_color(bg)}
selection_background    {sanitize_color(accent)}
cursor                  {sanitize_color(fg)}
cursor_text_color       {sanitize_color(bg)}
url_color               {sanitize_color(accent)}
active_border_color     {sanitize_color(accent)}
inactive_border_color   {sanitize_color(muted)}
bell_border_color       {sanitize_color(accent)}
active_tab_foreground   {sanitize_color(bg)}
active_tab_background   {sanitize_color(accent)}
inactive_tab_foreground {sanitize_color(fg)}
inactive_tab_background {sanitize_color(bg)}
tab_bar_background      {sanitize_color(bg)}
color0  {sanitize_color(muted)}
color8  {sanitize_color(muted)}
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
color7  {sanitize_color(fg)}
color15 {sanitize_color(fg)}
color16 {sanitize_color(bgSecondary)}
"""
    kitty_dir = os.path.join(home, ".config", "kitty")
    os.makedirs(kitty_dir, exist_ok=True)
    with open(os.path.join(kitty_dir, "theme.conf"), "w") as f2:
        f2.write(kitty_theme)
    subprocess.run("kill -SIGUSR1 $(pidof kitty) 2>/dev/null", shell=True)
