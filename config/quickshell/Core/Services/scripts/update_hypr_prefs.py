#!/usr/bin/env python3
import json
import os
import re
import sys


def update_lua(content, updates):
    lines = content.split("\n")
    scope = []

    flat_updates = {}

    def flatten(d, prefix=""):
        for k, v in d.items():
            if isinstance(v, dict):
                flatten(v, prefix + k + ".")
            else:
                flat_updates[prefix + k] = v

    flatten(updates)

    out_lines = []
    i = 0
    seen_keys = set()
    seen_top_level = set()

    while i < len(lines):
        line = lines[i]

        m_config_end = re.search(r"^\s*\}\)", line)
        if m_config_end and len(scope) == 0:
            for top_k, top_v in updates.items():
                if top_k not in seen_top_level:
                    out_lines.append(f"        {top_k} = {{")

                    def write_block(d, indent_lvl):
                        for k, v in d.items():
                            indent = " " * (indent_lvl * 8)
                            if isinstance(v, dict):
                                out_lines.append(f"{indent}{k} = {{")
                                write_block(v, indent_lvl + 1)
                                out_lines.append(f"{indent}}},")
                            else:
                                v_str = (
                                    str(v).lower() if isinstance(v, bool) else str(v)
                                )
                                out_lines.append(f"{indent}{k} = {v_str},")

                    write_block(top_v, 2)
                    out_lines.append("        },")
            out_lines.append(line)
            i += 1
            continue

        m_start = re.search(r"^\s*([a-zA-Z0-9_]+)\s*=\s*\{", line)
        if m_start:
            scope_name = m_start.group(1)
            scope.append(scope_name)
            if len(scope) == 1:
                seen_top_level.add(scope_name)
            out_lines.append(line)
            i += 1
            continue

        m_end = re.search(r"^\s*\},?", line)
        if m_end and len(scope) > 0:
            current_prefix = ".".join(scope) + "."

            missing_in_scope = {}
            for k, v in flat_updates.items():
                if k.startswith(current_prefix) and k not in seen_keys:
                    sub_path = k[len(current_prefix) :].split(".")
                    curr = missing_in_scope
                    for p in sub_path[:-1]:
                        if p not in curr:
                            curr[p] = {}
                        curr = curr[p]
                    curr[sub_path[-1]] = v
                    seen_keys.add(k)

            if missing_in_scope:

                def write_missing(d, indent_lvl):
                    indent_str = " " * (indent_lvl * 8 - 8)
                    for mk, mv in d.items():
                        if isinstance(mv, dict):
                            out_lines.append(f"{indent_str}{mk} = {{")
                            write_missing(mv, indent_lvl + 1)
                            out_lines.append(f"{indent_str}}},")
                        else:
                            v_str = str(mv).lower() if isinstance(mv, bool) else str(mv)
                            out_lines.append(f"{indent_str}{mk} = {v_str},")

                write_missing(missing_in_scope, len(scope) + 2)

            scope.pop()
            out_lines.append(line)
            i += 1
            continue

        m_kv = re.search(r"^(\s*)([a-zA-Z0-9_]+)(\s*=\s*)([^,]+)(,?)", line)
        if m_kv and len(scope) > 0:
            key = m_kv.group(2)
            full_key = ".".join(scope) + "." + key
            if full_key in flat_updates:
                val = flat_updates[full_key]
                v_str = str(val).lower() if isinstance(val, bool) else str(val)
                out_lines.append(
                    f"{m_kv.group(1)}{key}{m_kv.group(3)}{v_str}{m_kv.group(5)}"
                )
                seen_keys.add(full_key)
                i += 1
                continue

        out_lines.append(line)
        i += 1

    return "\n".join(out_lines)


def main():
    if len(sys.argv) < 2:
        return

    try:
        updates = json.loads(sys.argv[1])
    except json.JSONDecodeError:
        return

    prefs_path = os.path.expanduser("~/.config/hypr/userprefs.lua")
    if not os.path.exists(prefs_path):
        return

    with open(prefs_path, "r") as f:
        content = f.read()

    new_content = update_lua(content, updates)

    with open(prefs_path, "w") as f:
        f.write(new_content)


if __name__ == "__main__":
    main()
