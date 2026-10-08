#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import json
import os
import urllib.error
import urllib.parse
import urllib.request


def fetch_json(url, token=None):
    req = urllib.request.Request(url)
    req.add_header("User-Agent", "Minflair-Shell")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.URLError as e:
        return {"error": str(e)}


def download_avatar(url, dest_path):
    if not url:
        return False
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Minflair-Shell"})
        with urllib.request.urlopen(req, timeout=8) as response:
            data = response.read()
            tmp_path = dest_path + ".tmp"
            with open(tmp_path, "wb") as f:
                f.write(data)
            os.replace(tmp_path, dest_path)
        return True
    except Exception:
        return False


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Missing username"}))
        return

    user = sys.argv[1]
    token = sys.argv[2] if len(sys.argv) > 2 else None

    result = {}

    cache_dir = os.path.expanduser("~/.cache/quickshell")
    os.makedirs(cache_dir, exist_ok=True)
    clean_user = "".join(c for c in user if c.isalnum() or c in ("-", "_")).strip()
    avatar_path = (
        os.path.join(cache_dir, f"github_avatar_{clean_user}.png")
        if clean_user
        else os.path.join(cache_dir, "github_avatar.png")
    )

    # 1. Fetch Profile
    if token:
        profile = fetch_json("https://api.github.com/user", token)
        if "login" in profile and profile["login"].lower() == user.lower():
            result["profile"] = profile
            result["hasToken"] = True
        else:
            profile = fetch_json(
                f"https://api.github.com/users/{urllib.parse.quote(user)}"
            )
            result["profile"] = profile
            result["hasToken"] = False
            token = None  # Token is invalid or for wrong user
    else:
        profile = fetch_json(f"https://api.github.com/users/{urllib.parse.quote(user)}")
        result["profile"] = profile
        result["hasToken"] = False

    # Download and cache avatar locally to avoid Qt network/SSL issues
    avatar_url = (
        profile.get("avatar_url")
        if isinstance(profile, dict) and "avatar_url" in profile
        else None
    )
    if not avatar_url:
        avatar_url = f"https://github.com/identicons/{urllib.parse.quote(user)}.png"

    download_avatar(avatar_url, avatar_path)
    if os.path.exists(avatar_path):
        result["avatar_path"] = avatar_path

    # 2. Fetch Repos
    if token:
        repos = fetch_json(
            "https://api.github.com/user/repos?per_page=100&type=owner", token
        )
    else:
        repos = fetch_json(
            f"https://api.github.com/users/{urllib.parse.quote(user)}/repos?per_page=100"
        )
    result["repos"] = repos if isinstance(repos, list) else []

    # 3. Fetch Commits
    if token:
        commits = fetch_json(
            f"https://api.github.com/search/commits?q=author:{urllib.parse.quote(user)}",
            token,
        )
        result["commits"] = commits
    else:
        result["commits"] = {"total_count": 0}

    print(json.dumps(result))


if __name__ == "__main__":
    main()
