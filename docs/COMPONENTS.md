# Components and partial adoption

Minflair is split into components. A component groups everything needed to
integrate one application or one system behaviour:

- the configuration paths copied from the repository;
- the packages installed by the installer;
- the theme appliers that write colours;
- the font appliers that write typography;
- the reload command used after an update.

Components are opt-out. A component is enabled unless its id appears in the
user's preferences file. `quickshell` and `hyprland` are core and can never be
disabled.

## Manifest

The manifest lives at `config/quickshell/components.tsv` and ships with the
shell, so the runtime theme scripts can read it without the repository.

It is a tab-separated file with one row per component:

| Column | Meaning |
| --- | --- |
| `id` | Stable identifier used by preferences and scripts. |
| `label` | Human-readable name. |
| `category` | `core`, `terminal`, `desktop`, `apps` or `system`. |
| `core` | `1` for core components, `0` otherwise. |
| `paths` | Comma-separated repository paths (`config/kitty`, `home/.zshrc`). |
| `packages` | Comma-separated package names installed by the installer. |
| `theme` | Comma-separated appliers from `theme_appliers/`. |
| `font` | Comma-separated font targets handled by `apply_font.py`. |
| `reload` | Command used by install/update after deploying the component. |
| `description` | Short description shown by the selector and `list`. |

Lists are comma-separated. Empty fields are allowed. Lines starting with `#`
are comments.

## Preferences

Preferences live at `~/.config/minflair/preferences.conf`:

```text
# Minflair preferences v1
# One disabled component id per line.

kitty
nvim
starship
```

The file is a plain list so it can be read by the bash installer on a fresh
Arch installation, where Python and `jq` may not be available yet. Unknown
ids are ignored at runtime and reported by `validate`. Core ids are ignored.

A component that is not listed is enabled. New components added upstream are
therefore enabled by default and appear in the next interactive selection.

## What "disabled" means

A disabled component is never:

- copied by `install.sh` or `update.sh` (part 2);
- installed as a package (part 2);
- themed by `apply_theme.py`;
- updated by `apply_font.py`;
- reloaded or signalled (for example `killall -USR1 kitty`).

Disabling a component does **not** delete files that are already installed.
It only prevents Minflair from touching them again. This is deliberate: an
exclusion must never destroy a user's configuration.

## Runtime gating

`apply_theme.py` maps every applier to a component id and calls it only when
the component is enabled:

```python
APPLIERS = {
    "kitty": kitty.apply,
    "gtk": gtk.apply,
    # ...
}

def apply_appliers(home, colors, is_enabled=None):
    if is_enabled is None:
        is_enabled = components.enabled
    for component_id, apply in APPLIERS.items():
        if is_enabled(component_id):
            apply(home, colors)
```

Because the applier is not called at all, any reload signal implemented by
that applier is skipped as well.

`apply_font.py` uses the same rule. The `font-sync` component controls
propagation to external applications. The shell's own font preference is
always updated, because it is part of the shell and not an external app.

`apply_cursor.py` returns early when the `cursor` component is disabled.

## CLI

```bash
python3 config/quickshell/Scripts/minflair_components.py list
python3 config/quickshell/Scripts/minflair_components.py enabled kitty
python3 config/quickshell/Scripts/minflair_components.py paths --enabled
python3 config/quickshell/Scripts/minflair_components.py packages --disabled
python3 config/quickshell/Scripts/minflair_components.py validate --repo-root .
python3 config/quickshell/Scripts/minflair_components.py disable kitty nvim
python3 config/quickshell/Scripts/minflair_components.py enable kitty
```

`enabled` exits with `0` when the component is enabled and `1` when it is
disabled, so it can be used directly from bash.

`validate --repo-root .` also checks that:

- every directory under `config/` is mapped to exactly one component;
- every applier in `theme_appliers/` is mapped to a component;
- every declared path exists in the repository;
- preferences do not contain unknown or core ids.

## Tests

```bash
python3 -m unittest discover -s tests
```

The tests cover manifest coverage, preference loading, core protection and
runtime gating for the theme, font and cursor appliers.

## Adding a component

1. Add a row to `components.tsv`.
2. If the component has an applier, add it to the `theme` column.
3. If it has font handling, add it to the `font` column.
4. If it has a reload command, add it to the `reload` column.
5. Run `validate --repo-root .`.
6. Add a test only if the component has custom runtime behaviour.

The manifest is the single source of truth. Do not add component lists to
`install.sh`, `apply_theme.py` or `apply_font.py`.

## Current limitations

- `quickshell` and `hyprland` are core. A "shell only, keep my Hyprland"
  mode is not supported yet.
- Exclusions are per application, not per file. Keeping only some keybinds or
  one bar module is not supported.
- Disabling a component does not remove files that were already deployed.
