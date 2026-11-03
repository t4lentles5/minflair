#!/usr/bin/env python3
"""Resolve the AUR helper selected during installation.

The installer writes ``~/.config/minflair/aur-helper`` with either ``yay`` or
``paru``. Quickshell reads the same file so the package manager uses the helper
the user chose. ``MINFLAIR_AUR_HELPER`` and ``MINFLAIR_AUR_HELPER_FILE`` can
override the value, which keeps tests and automation self-contained.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

sys.dont_write_bytecode = True

DEFAULT = "yay"
VALID = ("yay", "paru")
ENV = "MINFLAIR_AUR_HELPER"
FILE_ENV = "MINFLAIR_AUR_HELPER_FILE"


def config_path() -> Path:
    override = os.environ.get(FILE_ENV)
    if override:
        return Path(override).expanduser()
    return Path.home() / ".config" / "minflair" / "aur-helper"


def normalize(value: str | None) -> str:
    value = (value or "").strip()
    return value if value in VALID else DEFAULT


def helper() -> str:
    override = os.environ.get(ENV)
    if override:
        return normalize(override)
    try:
        return normalize(config_path().read_text(encoding="utf-8"))
    except OSError:
        return DEFAULT


if __name__ == "__main__":
    print(helper())
