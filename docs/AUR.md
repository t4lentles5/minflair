# Installing Minflair from the AUR

The AUR packages install the `minflair` CLI and the configuration source under
`/usr/share/minflair`. The installer then copies the selected components into
your home directory, exactly like the bootstrap and git workflows.

| Package | Build | Best for |
| --- | --- | --- |
| `minflair` | Compiles the CLI from the release source | Normal installs |
| `minflair-bin` | Downloads the prebuilt static binary | Machines without a Rust toolchain |
| `minflair-git` | Tracks `main` | Testing unreleased changes |

All three provide `minflair` and conflict with each other.

## Install

```bash
yay -S minflair
# or
yay -S minflair-bin
# or
yay -S minflair-git
```

Then deploy the desktop configuration as your normal user:

```bash
minflair install
```

The component selector works the same as in the bootstrap installer. Reboot
after the first installation so services, themes and shell changes take effect.

## Update

The source is managed by pacman, so update it with your package manager and
then apply the new configuration:

```bash
sudo pacman -Syu
minflair update
```

Do **not** pass `--pull`. That flag runs `git pull` and rebuilds the CLI, which
does not apply to a package-managed copy. `minflair update` without `--pull`
uses the source already installed in `/usr/share/minflair`.

## Migrating from bootstrap or a git clone

`minflair` looks for the repository in several places. A path saved by
`bootstrap.sh` in `~/.config/minflair/repo` takes priority over
`/usr/share/minflair`, so remove the marker when switching to the AUR package:

```bash
rm -f ~/.config/minflair/repo
```

You can keep the old clone for reference, but the package copy is the one that
will be updated by pacman. If you want to be explicit, pass the packaged path:

```bash
minflair doctor --repo /usr/share/minflair
minflair install --repo /usr/share/minflair
```

## Uninstall

```bash
sudo pacman -Rns minflair
```

This removes the CLI and `/usr/share/minflair`. Your deployed configuration in
`~/.config`, your backups in `~/.minflair_backup` and the SDDM theme are left
untouched.

## Troubleshooting

- `minflair: command not found`: make sure `/usr/bin` is in `PATH`.
- `could not locate the Minflair repository`: remove a stale
  `~/.config/minflair/repo` marker or pass `--repo /usr/share/minflair`.
- `not a git checkout`: you passed `--pull` to a package-managed install. Use
  `sudo pacman -Syu` and then `minflair update`.
- `minflair doctor` reports a version mismatch: update the package and run
  `minflair update` so the configuration matches the binary.
