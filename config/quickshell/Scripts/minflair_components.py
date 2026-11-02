#!/usr/bin/env python3
"""Component manifest and preference handling for Minflair.

The manifest is a TSV file shipped with the shell. Preferences are a small
plain-text file that lists disabled component ids, one per line. Both the
installer and the runtime theme scripts use this module as the single source
of truth.

Preferences are opt-out: a component is enabled unless its id appears in the
preferences file. Core components can never be disabled.
"""

from __future__ import annotations

import argparse
import csv
import os
import sys
from dataclasses import dataclass
from pathlib import Path

DEFAULT_MANIFEST = Path(__file__).resolve().parent.parent / "components.tsv"
PREFS_ENV = "MINFLAIR_PREFS"
MANIFEST_ENV = "MINFLAIR_MANIFEST"
CORE_CATEGORY = "core"
MANIFEST_COLUMNS = (
    "id",
    "label",
    "category",
    "core",
    "paths",
    "packages",
    "theme",
    "font",
    "reload",
    "description",
)


class ComponentError(Exception):
    """Raised when the component manifest or preferences are invalid."""


@dataclass(frozen=True)
class Component:
    id: str
    label: str
    category: str
    core: bool
    paths: tuple[str, ...]
    packages: tuple[str, ...]
    theme: tuple[str, ...]
    font: tuple[str, ...]
    reload: str
    description: str


def manifest_path() -> Path:
    override = os.environ.get(MANIFEST_ENV)
    return Path(override).expanduser() if override else DEFAULT_MANIFEST


def preferences_path() -> Path:
    override = os.environ.get(PREFS_ENV)
    if override:
        return Path(override).expanduser()
    return Path.home() / ".config" / "minflair" / "preferences.conf"


def _split(value: str | None) -> tuple[str, ...]:
    if not value:
        return ()
    return tuple(part.strip() for part in value.split(",") if part.strip())


def load_manifest(path: Path | str | None = None) -> dict[str, Component]:
    manifest_file = Path(path) if path else manifest_path()
    if not manifest_file.is_file():
        raise ComponentError(f"Component manifest not found: {manifest_file}")

    components: dict[str, Component] = {}
    with manifest_file.open("r", encoding="utf-8", newline="") as handle:
        rows = (
            line
            for line in handle
            if line.strip() and not line.lstrip().startswith("#")
        )
        reader = csv.DictReader(rows, delimiter="\t")
        if reader.fieldnames is None or tuple(reader.fieldnames) != MANIFEST_COLUMNS:
            raise ComponentError(
                f"Invalid manifest header in {manifest_file}: {reader.fieldnames!r}"
            )

        for line_no, row in enumerate(reader, start=2):
            component_id = (row.get("id") or "").strip()
            if not component_id:
                raise ComponentError(
                    f"Missing component id at {manifest_file}:{line_no}"
                )
            if component_id in components:
                raise ComponentError(
                    f"Duplicate component id {component_id!r} at "
                    f"{manifest_file}:{line_no}"
                )
            components[component_id] = Component(
                id=component_id,
                label=(row.get("label") or component_id).strip(),
                category=(row.get("category") or "misc").strip(),
                core=(row.get("core") or "").strip() == "1",
                paths=_split(row.get("paths")),
                packages=_split(row.get("packages")),
                theme=_split(row.get("theme")),
                font=_split(row.get("font")),
                reload=(row.get("reload") or "").strip(),
                description=(row.get("description") or "").strip(),
            )

    if not components:
        raise ComponentError(f"Component manifest is empty: {manifest_file}")
    return components


def load_disabled(path: Path | str | None = None) -> set[str]:
    prefs_file = Path(path) if path else preferences_path()
    if not prefs_file.is_file():
        return set()

    disabled: set[str] = set()
    for line in prefs_file.read_text(encoding="utf-8").splitlines():
        value = line.strip()
        if value and not value.startswith("#"):
            disabled.add(value)
    return disabled


def enabled(
    component_id: str,
    manifest: dict[str, Component] | None = None,
    disabled: set[str] | None = None,
) -> bool:
    components = manifest if manifest is not None else load_manifest()
    component = components.get(component_id)
    if component is None:
        raise ComponentError(f"Unknown component: {component_id}")
    if component.core:
        return True
    if disabled is None:
        disabled = load_disabled()
    return component_id not in disabled


def write_disabled(
    component_ids: set[str] | list[str], path: Path | str | None = None
) -> Path:
    prefs_file = Path(path) if path else preferences_path()
    components = load_manifest()
    requested = set(component_ids)

    unknown = sorted(requested - set(components))
    if unknown:
        raise ComponentError(f"Unknown component ids: {', '.join(unknown)}")

    core = sorted(
        component_id for component_id in requested if components[component_id].core
    )
    if core:
        raise ComponentError(
            f"Core components cannot be disabled: {', '.join(core)}"
        )

    prefs_file.parent.mkdir(parents=True, exist_ok=True)
    body = [
        "# Minflair preferences v1",
        "# One disabled component id per line.",
        "",
    ]
    body.extend(sorted(requested))
    tmp = prefs_file.with_suffix(prefs_file.suffix + ".tmp")
    tmp.write_text("\n".join(body) + "\n", encoding="utf-8")
    tmp.replace(prefs_file)
    return prefs_file


def validate(
    manifest: dict[str, Component] | None = None,
    repo_root: Path | str | None = None,
    disabled: set[str] | None = None,
) -> list[str]:
    components = manifest if manifest is not None else load_manifest()
    warnings: list[str] = []

    for component in components.values():
        if component.core and component.category != CORE_CATEGORY:
            warnings.append(
                f"{component.id}: core component should use the "
                f"{CORE_CATEGORY!r} category"
            )
        if not component.core and component.category == CORE_CATEGORY:
            warnings.append(
                f"{component.id}: non-core component uses the "
                f"{CORE_CATEGORY!r} category"
            )

    applier_names: set[str] = set()
    if repo_root is not None:
        root = Path(repo_root)
        config_root = root / "config"
        mapped_config_dirs: dict[str, str] = {}

        for component in components.values():
            for raw_path in component.paths:
                path = Path(raw_path)
                if not (root / path).exists():
                    warnings.append(
                        f"{component.id}: path does not exist: {raw_path}"
                    )
                if len(path.parts) >= 2 and path.parts[0] == "config":
                    config_name = path.parts[1]
                    if config_name in mapped_config_dirs:
                        warnings.append(
                            f"config/{config_name}: mapped to both "
                            f"{mapped_config_dirs[config_name]} and "
                            f"{component.id}"
                        )
                    else:
                        mapped_config_dirs[config_name] = component.id

        if config_root.is_dir():
            for entry in sorted(config_root.iterdir()):
                if entry.is_dir() and entry.name not in mapped_config_dirs:
                    warnings.append(
                        f"config/{entry.name}: not mapped to any component"
                    )

        home_root = root / "home"
        mapped_home_entries = {
            Path(raw_path).parts[1]
            for component in components.values()
            for raw_path in component.paths
            if len(Path(raw_path).parts) >= 2
            and Path(raw_path).parts[0] == "home"
        }
        if home_root.is_dir():
            for entry in sorted(home_root.iterdir()):
                if entry.name not in mapped_home_entries:
                    warnings.append(
                        f"home/{entry.name}: not mapped to any component"
                    )

        applier_root = (
            root
            / "config"
            / "quickshell"
            / "Scripts"
            / "theme"
            / "theme_appliers"
        )
        if applier_root.is_dir():
            applier_names = {
                entry.stem for entry in applier_root.glob("*.py")
                if entry.stem != "__init__"
            }
            mapped_appliers = {
                applier
                for component in components.values()
                for applier in component.theme
            }
            for applier in sorted(applier_names - mapped_appliers):
                warnings.append(
                    f"theme_appliers/{applier}.py: not mapped to any component"
                )

    if applier_names:
        known_theme = applier_names | {"cursor"}
        for component in components.values():
            for applier in component.theme:
                if applier not in known_theme:
                    warnings.append(
                        f"{component.id}: unknown theme applier {applier!r}"
                    )

    if disabled is None:
        disabled = load_disabled()

    for component_id in sorted(disabled - set(components)):
        warnings.append(
            f"preferences: unknown component id {component_id!r} (ignored)"
        )
    for component_id in sorted(disabled):
        component = components.get(component_id)
        if component is not None and component.core:
            warnings.append(
                f"preferences: core component {component_id!r} cannot be "
                "disabled (ignored)"
            )

    return warnings


def _selected(
    components: dict[str, Component],
    disabled: set[str],
    want_disabled: bool,
) -> list[Component]:
    selected: list[Component] = []
    for component in components.values():
        is_disabled = not component.core and component.id in disabled
        if is_disabled == want_disabled:
            selected.append(component)
    return selected


def _print_list(components: dict[str, Component], disabled: set[str]) -> None:
    print(f"{'ID':<12} {'CATEGORY':<10} {'CORE':<5} {'STATUS':<9} DESCRIPTION")
    for component in components.values():
        if component.core:
            status = "core"
        elif component.id in disabled:
            status = "disabled"
        else:
            status = "enabled"
        print(
            f"{component.id:<12} {component.category:<10} "
            f"{'yes' if component.core else 'no':<5} {status:<9} "
            f"{component.description}"
        )


def _print_values(
    components: dict[str, Component],
    disabled: set[str],
    want_disabled: bool,
    attribute: str,
) -> None:
    values: list[str] = []
    for component in _selected(components, disabled, want_disabled):
        values.extend(getattr(component, attribute))
    for value in dict.fromkeys(values):
        print(value)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="minflair_components.py",
        description="Inspect and edit Minflair component preferences.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("list", help="show every component and its status")

    enabled_parser = subparsers.add_parser(
        "enabled", help="check whether a component is enabled"
    )
    enabled_parser.add_argument("id")

    for name, attribute in (("paths", "paths"), ("packages", "packages")):
        value_parser = subparsers.add_parser(
            name, help=f"print {attribute} for enabled or disabled components"
        )
        group = value_parser.add_mutually_exclusive_group()
        group.add_argument(
            "--enabled",
            action="store_true",
            help="only components that are enabled (default)",
        )
        group.add_argument(
            "--disabled",
            action="store_true",
            help="only components that are disabled",
        )

    validate_parser = subparsers.add_parser(
        "validate", help="check the manifest and preferences"
    )
    validate_parser.add_argument(
        "--repo-root",
        type=Path,
        help="also check that every config directory and applier is mapped",
    )

    for name in ("enable", "disable"):
        edit_parser = subparsers.add_parser(
            name, help=f"{name} one or more components"
        )
        edit_parser.add_argument("ids", nargs="+")

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        components = load_manifest()
        disabled = load_disabled()

        if args.command == "list":
            _print_list(components, disabled)
            return 0

        if args.command == "enabled":
            is_enabled = enabled(args.id, components, disabled)
            print("true" if is_enabled else "false")
            return 0 if is_enabled else 1

        if args.command == "paths":
            _print_values(
                components, disabled, args.disabled, "paths"
            )
            return 0

        if args.command == "packages":
            _print_values(
                components, disabled, args.disabled, "packages"
            )
            return 0

        if args.command == "validate":
            warnings = validate(components, args.repo_root, disabled)
            for warning in warnings:
                print(f"warning: {warning}", file=sys.stderr)
            if warnings:
                return 1
            print("components: ok")
            return 0

        if args.command in ("enable", "disable"):
            # Drop unknown and core ids that may come from an older version
            # or a manual edit before applying the requested change.
            known_disabled = {
                component_id
                for component_id in disabled
                if component_id in components
                and not components[component_id].core
            }
            if args.command == "enable":
                write_disabled(known_disabled - set(args.ids))
            else:
                write_disabled(known_disabled | set(args.ids))
            return 0

        parser.error(f"unknown command: {args.command}")
        return 2
    except ComponentError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
