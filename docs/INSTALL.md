# Install, update and partial adoption

Minflair installs a set of components. Each component groups configuration
files, packages, theme appliers and reload commands. You can keep your own
configuration for some applications while using the rest of Minflair.

The component list lives in `config/quickshell/components.tsv`. See
[COMPONENTS.md](COMPONENTS.md) for the manifest format and the runtime gating
rules.

## Requirements

- Arch Linux or an Arch-based distribution.
- A normal user account. `minflair install` and `minflair update` refuse to run
  as root.
- `git`, `base-devel` and `pacman`. The installer bootstraps `yay` when it is
  missing.
- An interactive terminal for the selector. Automation and non-interactive
  usage are documented in [ADVANCED.md](ADVANCED.md).

## First install

### One command

On Arch Linux, from a fresh system:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/t4lentles5/minflair/main/bootstrap.sh)"
```

The bootstrap script:

1. installs `git`, `base-devel` and Rust when they are missing;
2. clones Minflair into `~/.minflair` (or updates an existing clone);
3. builds the CLI and installs it in `~/.local/bin/minflair`;
4. saves the repository path in `~/.config/minflair/repo`;
5. runs `minflair install` with the flags you pass.

The CLI lands in `~/.local/bin`, which Minflair's zsh configuration adds to
`PATH`. For other shells, add that directory manually.

Keep the terminal attached. Use `bash -c "$(curl ...)"` instead of
`curl ... | bash`, because the component selector reads from the terminal. To
audit the script or pin a version, download it first:

```bash
curl -fsSL https://raw.githubusercontent.com/t4lentles5/minflair/main/bootstrap.sh \
  -o /tmp/minflair-bootstrap.sh
MINFLAIR_REF=v2.2.0 bash /tmp/minflair-bootstrap.sh
```

Useful overrides: `MINFLAIR_DIR` (clone directory), `MINFLAIR_BIN_DIR` (CLI
destination), `MINFLAIR_REPO_URL` (remote) and `MINFLAIR_REF` (branch or tag).
See [ADVANCED.md](ADVANCED.md#bootstrap-environment-variables).

### From git

```bash
git clone https://github.com/t4lentles5/minflair.git ~/.minflair
cd ~/.minflair

# Install the CLI in ~/.cargo/bin (already in PATH with rustup)
cargo install --path cli --locked

minflair install
```

With no options and an interactive terminal, the component selector opens
before anything is changed. This is the recommended way to install Minflair.

`minflair` finds the repository automatically from the path saved by
`bootstrap.sh`, and when it is in `~/.minflair` (or `~/.dotfiles`). For a clone
in another location, pass `--repo <path>` or set `MINFLAIR_REPO`.

If you prefer not to install the CLI, `./install.sh` remains a compatibility
entrypoint with the same selector, preferences and flags.

The first interactive install also asks whether to use `yay` or `paru` as the
AUR helper. The choice is saved in `~/.config/minflair/aur-helper` and is used
by the installer, the updater and the Package Manager. To change it later:

```bash
minflair install --aur-helper paru
```

### Selector controls

| Key | Action |
| --- | --- |
| `Up` / `k` | Move up |
| `Down` / `j` | Move down |
| `Space` | Enable or disable the highlighted component |
| `a` | Enable every optional component |
| `n` | Disable every optional component |
| `/` | Search by id or description |
| `Esc` | Clear the search |
| `Enter` | Review the selection and continue |
| `q` | Cancel without changing anything |

Core components (`quickshell` and `hyprland`) are always enabled and cannot be
toggled. On wide terminals the selector shows a description panel next to the
list. `Enter` opens a review screen with the components that will be installed
and skipped; preferences are saved only after you confirm.

The `zsh` component includes the login shell change: selecting it sets zsh as
your default shell. If Starship is disabled, zsh falls back to a basic prompt.

## Change the selection later

The selector is the recommended way to change components:

```bash
./install.sh --select
```

To disable or re-enable a specific component without opening the selector:

```bash
# Keep everything except Kitty and Neovim
./install.sh --exclude kitty,nvim

# Re-enable Kitty
./install.sh --include kitty
```

`--exclude` and `--include` persist the choice. For `--only`, `--dry-run`,
`--no-input`, `--no-packages` and the complete flag reference, see
[ADVANCED.md](ADVANCED.md).

## Preferences

`~/.config/minflair/preferences.conf` is a flat text file:

```text
# Minflair preferences v1
# One disabled component id per line.

kitty
nvim
starship
```

A component that is not listed is enabled. Deleting the file restores the
default: every component is installed. Unknown ids are ignored at runtime and
reported as warnings by the installer.

The file is plain text on purpose. It can be read on a fresh Arch installation
before Python is installed, and it is easy to edit by hand.

## What a disabled component means

A disabled component is not:

- copied by `minflair install` or `minflair update`;
- installed or updated as a package;
- themed by `apply_theme.py`;
- updated by `apply_font.py`;
- changed by `apply_cursor.py`;
- reloaded or signalled after an update.

Disabling a component does **not** delete files that are already installed. It
only prevents Minflair from touching them again. This makes exclusions safe:
you can try a component, disable it, and your previous files stay where they
are.

## Updating

With `minflair` in `PATH`, pull, rebuild and update in one step:

```bash
minflair update --pull
```

`--pull` runs `git pull --ff-only` and then rebuilds and reinstalls the CLI
automatically. Use `--no-build` to skip the rebuild, or omit `--pull` if you
already pulled:

```bash
minflair update
```

`minflair update` reads the saved preferences and only copies, installs, themes
and reloads enabled components. It never reintroduces a component that was
excluded. It only opens the selector with `--select`; a normal update keeps the
saved selection.

To change the selection during an update:

```bash
minflair update --select
minflair update --exclude nvim
minflair update --include kitty
```

`./update.sh` remains a compatibility entrypoint with the same flags and the
same native pipeline. For a dry run or automation, see
[ADVANCED.md](ADVANCED.md).

### Restoring a backup

The updater writes backups to `~/.minflair_backup/<timestamp>/`. To restore
the files it replaced:

```bash
backup=~/.minflair_backup/<timestamp>
[[ -d "$backup" ]] || backup=~/.dotfiles_backup/<timestamp>
cp -a "$backup/config/." ~/.config/
cp -a "$backup/home/." ~/
```

The second line keeps backups made by older versions restorable: they remain
in `~/.dotfiles_backup/<timestamp>/` and are not deleted.

To preview the SDDM theme without logging out:

```bash
sddm-greeter --test-mode --theme /usr/share/sddm/themes/minflair-sddm
```

## Compatibility with an existing setup

- Files that conflict with an enabled component are backed up to
  `~/.minflair_backup/<timestamp>/` before being replaced.
- Files that belong to disabled components are never read, copied or backed
  up by Minflair.
- Backups are written under `~/.minflair_backup/<timestamp>/`. Backups from
  older versions stay in `~/.dotfiles_backup/<timestamp>/` and are not deleted.
- `minflair update` preserves `~/.config/zsh/zhistory` when the `zsh`
  component is enabled.

## Troubleshooting

**The selector does not appear.** It needs an interactive terminal. Run
`minflair install --select` from a terminal. If the terminal is not
interactive, use `--exclude`/`--include` or see [ADVANCED.md](ADVANCED.md).

**A component I disabled is still themed.** Check that the preference file
contains the component id and re-run `minflair update`. Files already written
by an older version are not deleted, but they are not updated again.

**A package I disabled was still installed.** It may be a dependency of an
enabled component. Minflair only removes packages from its own explicit lists;
`pacman` still resolves dependencies.

**I want everything back.** Remove `~/.config/minflair/preferences.conf` and run
`minflair update`.
