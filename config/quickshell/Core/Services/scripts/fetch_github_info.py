#!/usr/bin/env python3
import json
import sys
import urllib.error
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


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Missing username"}))
        return

    user = sys.argv[1]
    token = sys.argv[2] if len(sys.argv) > 2 else None

    result = {}

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
