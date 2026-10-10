import sys

sys.dont_write_bytecode = True

import json
import os
import re
import time
import urllib.request

CACHE_DIR = os.path.expanduser("~/.cache/quickshell")
CACHE_TTL = 3600  # 1 hour in seconds


def get_cache_file(username):
    safe_name = "".join(c for c in username if c.isalnum() or c in ("-", "_"))
    return os.path.join(CACHE_DIR, f"github_contributions_{safe_name}.json")


def load_cached_contributions(username, max_age=CACHE_TTL):
    cache_file = get_cache_file(username)
    if not os.path.exists(cache_file):
        return None
    try:
        mtime = os.path.getmtime(cache_file)
        if max_age is not None and (time.time() - mtime > max_age):
            return None
        with open(cache_file, "r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, list) and len(data) > 0:
                return data
    except Exception:
        pass
    return None


def save_cached_contributions(username, data):
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        cache_file = get_cache_file(username)
        temp_file = cache_file + ".tmp"
        with open(temp_file, "w", encoding="utf-8") as f:
            json.dump(data, f)
        os.replace(temp_file, cache_file)
    except Exception:
        pass


from html.parser import HTMLParser


class GithubParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.days = {}
        self.tooltips = {}
        self.current_tooltip_id = None
        self.current_tooltip_text = []

    def handle_starttag(self, tag, attrs):
        attr_dict = dict(attrs)
        if tag == "td" and "data-date" in attr_dict and "data-level" in attr_dict:
            td_id = attr_dict.get("id")
            if td_id:
                self.days[td_id] = {
                    "date": attr_dict["data-date"],
                    "level": int(attr_dict["data-level"]),
                }
        elif tag == "tool-tip" and "for" in attr_dict:
            self.current_tooltip_id = attr_dict["for"]
            self.current_tooltip_text = []

    def handle_data(self, data):
        if self.current_tooltip_id:
            self.current_tooltip_text.append(data)

    def handle_endtag(self, tag):
        if tag == "tool-tip" and self.current_tooltip_id:
            self.tooltips[self.current_tooltip_id] = "".join(
                self.current_tooltip_text
            ).strip()
            self.current_tooltip_id = None


def fetch_contributions(username):
    # Return fresh cache if available
    cached = load_cached_contributions(username, max_age=CACHE_TTL)
    if cached is not None:
        return cached

    url = f"https://github.com/users/{username}/contributions"
    try:
        req = urllib.request.Request(
            url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"}
        )
        with urllib.request.urlopen(req, timeout=8) as response:
            html = response.read().decode("utf-8")

        parser = GithubParser()
        parser.feed(html)
        result = []
        for td_id, day_data in parser.days.items():
            day_data["tooltip"] = parser.tooltips.get(td_id, "")
            result.append(day_data)

        result.sort(key=lambda x: x["date"])

        if result:
            save_cached_contributions(username, result)
            return result
    except Exception:
        pass

    # Fall back to stale cache if network request failed
    stale = load_cached_contributions(username, max_age=None)
    if stale is not None:
        return stale

    return []


def fetch_contributions_graphql(username, token):
    cached = load_cached_contributions(username, max_age=CACHE_TTL)
    if cached is not None:
        return cached

    url = "https://api.github.com/graphql"
    query = """
    query {
      user(login: "%s") {
        contributionsCollection {
          contributionCalendar {
            weeks {
              contributionDays {
                contributionCount
                date
                color
              }
            }
          }
        }
      }
    }
    """ % username

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64)",
    }
    data = json.dumps({"query": query}).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers)

    try:
        with urllib.request.urlopen(req, timeout=8) as response:
            res_data = json.loads(response.read().decode("utf-8"))

        calendar = res_data["data"]["user"]["contributionsCollection"][
            "contributionCalendar"
        ]
        result = []
        for week in calendar["weeks"]:
            for day in week["contributionDays"]:
                count = day["contributionCount"]
                date = day["date"]
                color = day["color"]

                level = 0
                c = color.lower()
                if c in ["#0e4429", "#9be9a8"]:
                    level = 1
                elif c in ["#006d32", "#40c463"]:
                    level = 2
                elif c in ["#26a641", "#30a14e"]:
                    level = 3
                elif c in ["#39d353", "#216e39"]:
                    level = 4
                elif count > 0:
                    level = max(1, min(4, count // 3))

                tooltip = (
                    f"{count} contributions on {date}"
                    if count > 0
                    else f"No contributions on {date}"
                )

                result.append(
                    {
                        "date": date,
                        "level": level,
                        "count": count,
                        "tooltip": tooltip,
                        "color": color,
                    }
                )

        result.sort(key=lambda x: x["date"])
        if result:
            save_cached_contributions(username, result)
            return result
    except Exception:
        pass

    return fetch_contributions(username)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps([]))
        sys.exit(1)
    username = sys.argv[1].strip()
    token = sys.argv[2].strip() if len(sys.argv) > 2 else ""
    if not username:
        print(json.dumps([]))
        sys.exit(0)

    if token:
        data = fetch_contributions_graphql(username, token)
    else:
        data = fetch_contributions(username)

    print(json.dumps(data))
