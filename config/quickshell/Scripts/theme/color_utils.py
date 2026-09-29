import sys

sys.dont_write_bytecode = True


def sanitize_color(c):
    s = str(c)
    if s.startswith("#") and len(s) > 7:
        return "#" + s[-6:]
    return s


def get_brightness(c):
    s = str(c)
    r, g, b = 0, 0, 0
    if s.startswith("#"):
        if len(s) == 7:
            r = int(s[1:3], 16) / 255.0
            g = int(s[3:5], 16) / 255.0
            b = int(s[5:7], 16) / 255.0
        elif len(s) == 9:
            r = int(s[3:5], 16) / 255.0
            g = int(s[5:7], 16) / 255.0
            b = int(s[7:9], 16) / 255.0
        elif len(s) == 4:
            r = int(s[1:2] * 2, 16) / 255.0
            g = int(s[2:3] * 2, 16) / 255.0
            b = int(s[3:4] * 2, 16) / 255.0
    return r * 0.299 + g * 0.587 + b * 0.114


def hypr_color(c, alpha=""):
    s = str(c)
    if s.startswith("#"):
        s = s[1:]
    if len(s) == 8:
        a = s[0:2]
        rgb = s[2:]
        if alpha:
            return f"rgba({rgb}{alpha})"
        else:
            return f"rgba({rgb}{a})"
    if alpha:
        return f"rgba({s}{alpha})"
    else:
        return f"rgb({s})"


def blend_hex(f_hex, b_hex, w):
    f, b = f_hex.lstrip("#"), b_hex.lstrip("#")
    if len(f) == 3:
        f = "".join(c * 2 for c in f)
    if len(b) == 3:
        b = "".join(c * 2 for c in b)
    if len(f) > 6:
        f = f[-6:]
    if len(b) > 6:
        b = b[-6:]
    if len(f) != 6 or len(b) != 6:
        return b_hex
    rf, gf, bf = int(f[0:2], 16), int(f[2:4], 16), int(f[4:6], 16)
    rb, gb, bb = int(b[0:2], 16), int(b[2:4], 16), int(b[4:6], 16)
    return f"#{int(rf*w + rb*(1-w)):02x}{int(gf*w + gb*(1-w)):02x}{int(bf*w + bb*(1-w)):02x}"


def rgb_to_hsl(r, g, b):
    r_pct = r / 255.0
    g_pct = g / 255.0
    b_pct = b / 255.0
    max_c = max(r_pct, g_pct, b_pct)
    min_c = min(r_pct, g_pct, b_pct)
    l = (max_c + min_c) / 2.0
    if max_c == min_c:
        h = s = 0.0
    else:
        d = max_c - min_c
        s = d / (2.0 - max_c - min_c) if l > 0.5 else d / (max_c + min_c)
        if max_c == r_pct:
            h = (g_pct - b_pct) / d + (6.0 if g_pct < b_pct else 0.0)
        elif max_c == g_pct:
            h = (b_pct - r_pct) / d + 2.0
        else:
            h = (r_pct - g_pct) / d + 4.0
        h /= 6.0
    return h * 360.0, s, l


def hue_distance(h1, h2):
    d = abs(h1 - h2) % 360
    return 360 - d if d > 180 else d


def clamp_rgb(val):
    return max(0, min(255, int(val)))


def to_hex(r, g, b):
    return f"#{r:02x}{g:02x}{b:02x}"


def force_hsl(h, s, l, target_s, target_l):
    s = max(target_s, s)
    c = (1.0 - abs(2.0 * target_l - 1.0)) * s
    x = c * (1.0 - abs((h / 60.0) % 2.0 - 1.0))
    m = target_l - c / 2.0
    if 0 <= h < 60:
        r, g, b = c, x, 0
    elif 60 <= h < 120:
        r, g, b = x, c, 0
    elif 120 <= h < 180:
        r, g, b = 0, c, x
    elif 180 <= h < 240:
        r, g, b = 0, x, c
    elif 240 <= h < 300:
        r, g, b = x, 0, c
    else:
        r, g, b = c, 0, x
    return to_hex(
        clamp_rgb((r + m) * 255), clamp_rgb((g + m) * 255), clamp_rgb((b + m) * 255)
    )


def get_chroma(color_obj):
    return (
        max(color_obj["r"], color_obj["g"], color_obj["b"])
        - min(color_obj["r"], color_obj["g"], color_obj["b"])
    ) / 255.0


def color_distance(c1, c2):
    r1, g1, b1 = int(c1[1:3], 16), int(c1[3:5], 16), int(c1[5:7], 16)
    r2, g2, b2 = int(c2[1:3], 16), int(c2[3:5], 16), int(c2[5:7], 16)
    return (r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2
