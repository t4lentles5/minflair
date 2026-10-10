#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import json
import os
import re
import subprocess

os.environ["LC_ALL"] = "C"


def get_installed_packages() -> list[dict]:
    try:
        all_info_proc = subprocess.run(
            ["pacman", "-Qi"], capture_output=True, text=True
        )
        if all_info_proc.returncode != 0:
            return []

        foreign_pkg_proc = subprocess.run(
            ["pacman", "-Qm"], capture_output=True, text=True
        )
        foreign_names = {
            line.split()[0]
            for line in foreign_pkg_proc.stdout.strip().split("\n")
            if line
        }

        sync_pkg_proc = subprocess.run(
            ["pacman", "-Sl"], capture_output=True, text=True
        )
        repo_map = {}
        for line in sync_pkg_proc.stdout.strip().split("\n"):
            parts = line.split()
            if len(parts) >= 2:
                repo_map[parts[1]] = parts[0]

        packages = []
        current_pkg = {}

        for line in all_info_proc.stdout.split("\n"):
            if not line.strip():
                if current_pkg.get("name"):
                    name = current_pkg["name"]
                    is_aur = name in foreign_names
                    packages.append(
                        {
                            "name": name,
                            "version": current_pkg.get("version", ""),
                            "repo": "aur" if is_aur else repo_map.get(name, "pacman"),
                            "source": "AUR" if is_aur else "pacman",
                            "description": current_pkg.get("description", ""),
                            "installed": True,
                            "is_full_list": True,
                        }
                    )
                current_pkg = {}
                continue

            if " : " in line:
                key, val = line.split(" : ", 1)
                key = key.strip()
                val = val.strip()
                if key == "Name":
                    current_pkg["name"] = val
                elif key == "Version":
                    current_pkg["version"] = val
                elif key == "Description":
                    current_pkg["description"] = val

        return sorted(packages, key=lambda x: x["name"].lower())
    except Exception:
        return []


def search_packages(query: str) -> list[dict]:
    if not query or len(query) < 2:
        return []

    try:
        result = subprocess.run(
            ["yay", "-Ss", query],
            capture_output=True,
            text=True,
            timeout=15,
        )
        if result.returncode != 0:
            return []

        lines = result.stdout.strip().split("\n")
        packages = []
        i = 0
        while i < len(lines):
            header = lines[i].strip()
            description = lines[i + 1].strip() if i + 1 < len(lines) else ""
            i += 2

            if not header:
                continue

            try:
                repo_name, rest = header.split(" ", 1)
                repo, name = repo_name.split("/", 1)
            except ValueError:
                continue

            rest_parts = rest.split()
            version = rest_parts[0] if rest_parts else ""
            installed = "(Installed)" in header or "(Installed:" in header
            source = "AUR" if repo == "aur" else "pacman"

            packages.append(
                {
                    "name": name,
                    "version": version,
                    "repo": repo,
                    "source": source,
                    "description": description,
                    "installed": installed,
                }
            )

        query_lower = query.lower()

        def sort_key(pkg):
            name_lower = pkg["name"].lower()
            if name_lower == query_lower:
                tier = 0
            elif name_lower.startswith(query_lower):
                tier = 1
            elif re.search(r"(^|[-_])" + re.escape(query_lower), name_lower):
                tier = 2
            elif query_lower in name_lower:
                tier = 3
            else:
                tier = 4

            is_installed = 0 if pkg["installed"] else 1
            is_aur = 1 if pkg["source"] == "AUR" else 0
            return (tier, is_installed, is_aur, len(name_lower))

        packages.sort(key=sort_key)
        return packages[:50]
    except Exception:
        return []


def get_updates() -> list[dict]:
    packages = []
    try:
        res = subprocess.run(["checkupdates"], capture_output=True, text=True)
        if res.stdout:
            for line in res.stdout.strip().split("\n"):
                if not line:
                    continue
                parts = line.split()
                if len(parts) >= 4 and parts[2] == "->":
                    pkgname = parts[0]
                    old_ver = parts[1]
                    new_ver = parts[3]
                    packages.append(
                        {
                            "name": pkgname,
                            "version": f"{old_ver} -> {new_ver}",
                            "repo": "pacman",
                            "source": "pacman",
                            "description": "",
                            "installed": True,
                        }
                    )
    except Exception:
        pass

    try:
        res = subprocess.run(
            ["yay", "-Qua", "--color=never"], capture_output=True, text=True
        )
        if res.stdout:
            for line in res.stdout.strip().split("\n"):
                if not line:
                    continue
                parts = line.split()
                if len(parts) >= 4 and parts[2] == "->":
                    pkgname = parts[0]
                    old_ver = parts[1]
                    new_ver = parts[3]
                    packages.append(
                        {
                            "name": pkgname,
                            "version": f"{old_ver} -> {new_ver}",
                            "repo": "aur",
                            "source": "AUR",
                            "description": "",
                            "installed": True,
                        }
                    )
    except Exception:
        pass

    seen = set()
    deduped_packages = []
    for p in packages:
        if p["name"] not in seen:
            seen.add(p["name"])
            deduped_packages.append(p)
    packages = deduped_packages

    if packages:
        try:
            pkg_names = [p["name"] for p in packages]
            info_proc = subprocess.run(
                ["pacman", "-Qi"] + pkg_names, capture_output=True, text=True
            )
            desc_map = {}
            current_name = None
            if info_proc.stdout:
                for line in info_proc.stdout.split("\n"):
                    if " : " in line:
                        k, v = line.split(" : ", 1)
                        k, v = k.strip(), v.strip()
                        if k == "Name":
                            current_name = v
                        elif k == "Description" and current_name:
                            desc_map[current_name] = v
            for p in packages:
                p["description"] = desc_map.get(
                    p["name"], f"Update available: {p['version']}"
                )
        except Exception:
            for p in packages:
                p["description"] = f"Update available: {p['version']}"

    return sorted(packages, key=lambda x: x["name"].lower())


def get_featured_packages(category_id: str = "featured") -> list[dict]:
    try:
        import os

        script_dir = os.path.dirname(os.path.realpath(__file__))
        json_path = os.path.join(script_dir, "featured_packages.json")
        with open(json_path, "r") as f:
            data = json.load(f)

        packages_dict = data.get("packages", {})
        if category_id == "all":
            popular_names = []
            for names in packages_dict.values():
                popular_names.extend(names)
            # Remove duplicates while preserving order
            popular_names = list(dict.fromkeys(popular_names))
        else:
            popular_names = packages_dict.get(
                category_id, packages_dict.get("featured", [])
            )

        if not popular_names:
            return []
    except Exception:
        return []

    packages = []
    try:
        # Get installed packages quickly
        installed_proc = subprocess.run(
            ["pacman", "-Qq"], capture_output=True, text=True
        )
        installed_set = set(installed_proc.stdout.split())

        # Get info for all popular packages at once using yay -Si
        result = subprocess.run(
            ["yay", "-Si"] + popular_names,
            capture_output=True,
            text=True,
            timeout=15,
        )

        current_pkg = {}
        for line in result.stdout.split("\n"):
            if not line.strip():
                if current_pkg.get("name"):
                    repo = current_pkg.get("repo", "aur")
                    packages.append(
                        {
                            "name": current_pkg["name"],
                            "version": current_pkg.get("version", ""),
                            "repo": repo,
                            "source": "AUR" if repo.lower() == "aur" else "pacman",
                            "description": current_pkg.get("description", ""),
                            "installed": current_pkg["name"] in installed_set,
                        }
                    )
                current_pkg = {}
                continue

            if " : " in line:
                key, val = line.split(" : ", 1)
                key = key.strip()
                val = val.strip()
                if key == "Name":
                    current_pkg["name"] = val
                elif key == "Version":
                    current_pkg["version"] = val
                elif key == "Description":
                    current_pkg["description"] = val
                elif key == "Repository":
                    current_pkg["repo"] = val

        # Sort packages in the same order as popular_names
        order_map = {name: i for i, name in enumerate(popular_names)}
        packages.sort(key=lambda x: order_map.get(x["name"].lower(), 999))

        return packages
    except Exception:
        return []


if __name__ == "__main__":
    if "--list-installed" in sys.argv:
        print(json.dumps(get_installed_packages()))
        sys.exit(0)

    if "--list-updates" in sys.argv:
        print(json.dumps(get_updates()))
        sys.exit(0)

    if "--featured" in sys.argv:
        idx = sys.argv.index("--featured")
        cat = sys.argv[idx + 1] if len(sys.argv) > idx + 1 else "featured"
        print(json.dumps(get_featured_packages(cat)))
        sys.exit(0)

    if len(sys.argv) < 2:
        print("[]")
        sys.exit(0)

    query = sys.argv[1]
    print(json.dumps(search_packages(query)))
