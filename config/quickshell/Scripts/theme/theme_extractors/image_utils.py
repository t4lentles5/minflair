import os


def prepare_image(image_path):
    processing_path = image_path
    magick_path = image_path

    ext = os.path.splitext(image_path)[1].lower()
    if ext in [".gif", ".webp"]:
        home = os.path.expanduser("~")
        frames_dir = os.path.join(home, ".cache", "quickshell", "frames")
        os.makedirs(frames_dir, exist_ok=True)
        base_name = os.path.basename(image_path)
        cached_frame = os.path.join(frames_dir, base_name + ".jpg")

        need_extract = True
        if os.path.exists(cached_frame):
            src_mtime = os.path.getmtime(image_path)
            cache_mtime = os.path.getmtime(cached_frame)
            if cache_mtime >= src_mtime:
                need_extract = False

        if need_extract:
            try:
                import gi

                gi.require_version("GdkPixbuf", "2.0")
                from gi.repository import GdkPixbuf

                pixbuf = GdkPixbuf.Pixbuf.new_from_file(image_path)

                if pixbuf.get_has_alpha():
                    bg = GdkPixbuf.Pixbuf.new(
                        GdkPixbuf.Colorspace.RGB,
                        False,
                        8,
                        pixbuf.get_width(),
                        pixbuf.get_height(),
                    )
                    bg.fill(0x000000FF)
                    pixbuf.composite(
                        bg,
                        0,
                        0,
                        pixbuf.get_width(),
                        pixbuf.get_height(),
                        0,
                        0,
                        1.0,
                        1.0,
                        GdkPixbuf.InterpType.BILINEAR,
                        255,
                    )
                    pixbuf = bg

                pixbuf.savev(cached_frame, "jpeg", ["quality"], ["90"])
            except Exception as e:
                print("Warning: GdkPixbuf frame extraction failed:", e)
                cached_frame = None

        if cached_frame and os.path.exists(cached_frame):
            processing_path = cached_frame
            magick_path = cached_frame
        else:
            print("Warning: no cached frame available, using original file.")

    return processing_path, magick_path
