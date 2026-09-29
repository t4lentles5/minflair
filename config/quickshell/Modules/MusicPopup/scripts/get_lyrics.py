#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import argparse
import hashlib
import json
import os
import re
import urllib.parse
import urllib.request

CACHE_DIR = os.path.expanduser("~/.cache/quickshell/lyrics")
os.makedirs(CACHE_DIR, exist_ok=True)


def parse_lrc(lrc_str):
    lines = []
    plain_text = []
    synced = False
    for line in lrc_str.splitlines():
        line = line.strip()
        if not line:
            continue
        # Match [mm:ss.xx] or [mm:ss.xxx]
        match = re.match(r"^\[(\d+):(\d+\.\d+)\](.*)", line)
        if match:
            synced = True
            m, s, text = match.groups()
            time_sec = int(m) * 60 + float(s)
            lines.append({"time": time_sec, "text": text.strip()})
            if text.strip():
                plain_text.append(text.strip())
        else:
            if not line.startswith("["):  # Ignore tags like [ar:...]
                plain_text.append(line)

    return synced, lines, "\n".join(plain_text)


def get_cache_path(title, artist, duration):
    key = f"{title}-{artist}-{duration}".encode("utf-8")
    hash_str = hashlib.md5(key).hexdigest()
    return os.path.join(CACHE_DIR, f"{hash_str}.json")


def read_local_lrc(file_url):
    if not file_url or not file_url.startswith("file://"):
        return None
    try:
        path = urllib.parse.unquote(file_url[7:])
        if os.path.exists(path):
            base, ext = os.path.splitext(path)
            lrc_path = base + ".lrc"
            if os.path.exists(lrc_path):
                with open(lrc_path, "r", encoding="utf-8") as f:
                    return f.read()
    except Exception:
        pass
    return None


def fetch_lrclib(title, artist, duration, album=""):
    headers = {"User-Agent": "QuickshellMusic/1.0 (https://github.com/)"}

    # 1. Try exact match
    query = {"track_name": title, "artist_name": artist}
    if duration and duration > 0:
        query["duration"] = int(duration)
    if album:
        query["album_name"] = album

    url = "https://lrclib.net/api/get?" + urllib.parse.urlencode(query)
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=5) as res:
            data = json.loads(res.read().decode())
            if data.get("syncedLyrics") or data.get("plainLyrics"):
                return data
    except Exception:
        pass

    # 2. Try search fallback
    search_query = {"track_name": title, "artist_name": artist}
    url = "https://lrclib.net/api/search?" + urllib.parse.urlencode(search_query)
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=5) as res:
            data = json.loads(res.read().decode())
            if data and len(data) > 0:
                best = data[0]
                if best.get("syncedLyrics") or best.get("plainLyrics"):
                    return best
    except Exception:
        pass

    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--title", default="")
    parser.add_argument("--artist", default="")
    parser.add_argument("--album", default="")
    parser.add_argument("--duration", type=float, default=0)
    parser.add_argument("--file-url", default="")
    args = parser.parse_args()

    if not args.title:
        print(json.dumps({"success": False, "error": "No title provided"}))
        return

    cache_path = get_cache_path(args.title, args.artist, args.duration)

    if os.path.exists(cache_path):
        try:
            with open(cache_path, "r") as f:
                print(f.read())
                return
        except Exception:
            pass

    # Try local file first
    local_lrc_content = read_local_lrc(args.file_url)
    if local_lrc_content:
        synced, lines, plain = parse_lrc(local_lrc_content)
        result = {
            "success": True,
            "synced": synced,
            "lines": lines,
            "plainLyrics": plain,
            "source": "local",
        }
    else:
        # Fetch from LRCLIB
        lrclib_data = fetch_lrclib(args.title, args.artist, args.duration, args.album)
        if lrclib_data:
            synced_str = lrclib_data.get("syncedLyrics", "")
            plain_str = lrclib_data.get("plainLyrics", "")

            if synced_str:
                synced, lines, plain = parse_lrc(synced_str)
                result = {
                    "success": True,
                    "synced": synced,
                    "lines": lines,
                    "plainLyrics": plain_str or plain,
                    "source": "lrclib",
                }
            else:
                result = {
                    "success": True,
                    "synced": False,
                    "lines": [],
                    "plainLyrics": plain_str,
                    "source": "lrclib",
                }
        else:
            result = {"success": False, "error": "Not found"}

    json_out = json.dumps(result)
    try:
        with open(cache_path, "w") as f:
            f.write(json_out)
    except Exception:
        pass

    print(json_out)


if __name__ == "__main__":
    main()
