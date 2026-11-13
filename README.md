# mklbravo's dotfiles

Shared configuration for macOS, Ubuntu, Debian and Arch Linux. A small Bash installer manages explicit symbolic links, native packages and Git dependencies. No Mackup, Python or GNU-specific shell utilities are required. Bash 3.2 (included with macOS) is supported.

## Getting started

Install Git and Bash first. On macOS, also install [Homebrew](https://brew.sh) using its official instructions. On Linux, use the distribution's native package manager. The installer never bootstraps package managers, adds repositories or changes your default shell.

```sh
git clone https://github.com/mklbravo/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Read-only: inspect destinations and package/repository declarations.
./scripts/dotfiles plan

# Creates links, installs CLI packages and clones missing dependencies.
./scripts/dotfiles install

# Read-only: verify every managed symbolic link.
./scripts/dotfiles check
```

The repository can live anywhere; destinations use `$HOME` and `${XDG_CONFIG_HOME:-$HOME/.config}`. XDG paths must be absolute. Run as your normal user, not with `sudo`: only native system package operations request elevated privileges.

`install` does not start services or execute downloaded setup scripts. It does not launch Neovim or tmux. Open a new Zsh session after installation. Changing your login shell is a separate, manual action.

## Commands

| Command | Behavior |
| --- | --- |
| `plan` | Show current link states and declared packages/repositories; no network or writes |
| `check` | Check managed links; nonzero exit for missing, broken or conflicting links |
| `link` | Create missing links; leave correct links unchanged |
| `packages` | Install available CLI packages through brew, apt or pacman |
| `casks` | Install optional macOS GUI applications |
| `repositories` | Clone missing Git dependencies; check existing origins, never pull |
| `update-repositories` | Explicitly update clean, attached dependency checkouts using `git pull --ff-only` |
| `install` | Preflight conflicts, then run `link`, `packages` and `repositories` |

The same commands are available through Make, for example `make plan`, `make install` and `make check`. `make restore` remains an alias for `make install`.

Links and repositories can be installed independently: custom Zsh files live outside the Oh My Zsh framework checkout.

### Conflicts and backups

By default, an existing file, directory or incorrect symbolic link is a conflict. The installer does not overwrite it. Inspect conflicts with `plan`, then either move them manually or explicitly request backups:

```sh
./scripts/dotfiles link --backup
./scripts/dotfiles repositories --backup
./scripts/dotfiles install --backup
# Equivalent Make invocation:
make install ARGS=--backup
```

Backups are created lazily in a unique directory under `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups/`. Each move prints its original and backup paths. Symlinks are backed up as symlinks, not dereferenced. Keep their old targets until migration is complete. Restore a backup manually by removing only the newly managed link/checkout and moving the saved entry back to its printed destination.

Parents resolving inside this repository are rejected when a write would modify tracked configuration. For example, an old link of the entire `~/.config` directory into this repository must be migrated manually; `--backup` does not bypass this protection.

Installation is incremental, not transactional. A package/network failure can leave completed steps in place; rerun after resolving it. `check` only checks links, not package versions, application behavior or repository contents. `plan` shows repository declarations, not repository health.

### Packages

Edit `manifests/packages/brew.txt`, `apt.txt` or `pacman.txt`. Package names are native to each manager, not translated at runtime. Only macOS uses Homebrew; Ubuntu/Debian use apt and Arch uses pacman.

Already installed packages are skipped. Unavailable packages are reported and skipped so the remaining installation can continue; this is not a guarantee that every tool is installed. Availability and versions vary by distribution release, especially for `eza`, `gum`, `lazygit`, `starship` and `git-delta`. Git's pager configuration requires `delta`; install it from a trusted source if your distribution does not provide it. External Neovim configuration may require a newer Neovim than your distribution ships.

Refresh package metadata separately when needed (`sudo apt-get update`). On Arch, perform normal full system updates with `sudo pacman -Syu` before installing against an outdated sync database. The installer never runs `pacman -Sy`, adds third-party repositories or uses AUR helpers. Package managers may still install required dependencies or run their normal package hooks. Package upgrades are separate, native package-manager operations.

GUI applications are opt-in:

```sh
./scripts/dotfiles casks
```

`manifests/packages/macos-casks.txt` contains the former Brewfile's GUI applications. Linux GUI application installation is deliberately not automated.

### Repositories and plugins

`manifests/repositories.tsv` declares Oh My Zsh, its Zsh plugins, TPM, the tmux plugins and `mklbravo/nvim-config`. Public HTTPS URLs avoid requiring SSH keys during bootstrap. Existing GitHub SSH origins for the same repository are accepted too.

Oh My Zsh is cloned without running its setup script, so it cannot replace `.zshrc` or change your login shell. Its custom files and plugins live in `$XDG_CONFIG_HOME/zsh/custom`, separate from the framework checkout (`$ZSH_CUSTOM`). Automatic Oh My Zsh updates are disabled; use `update-repositories` explicitly. Updates refuse dirty checkouts and detached HEADs, and do not reset local changes. Repositories follow their cloned default branch, not pinned revisions.

TPM and the currently declared tmux plugins are cloned directly; no running tmux server is required. When adding a tmux plugin, add it to both `.tmux.conf` and `manifests/repositories.tsv` if the installer should manage its checkout. Additional plugins installed manually through TPM are outside the manifest.

Neovim is managed only through `mklbravo/nvim-config`, cloned to `$XDG_CONFIG_HOME/nvim`. The old local `init.vim` has been removed to avoid competing configurations. Neovim's own plugin setup runs according to that repository when you launch the editor, not during this installer.

### Configuration and local overrides

`manifests/links.tsv` maps repository paths to destinations with three tab-separated fields: source, destination, platform (`all`, `macos`, `linux`). Sources are relative to the repository; destinations use `home:` or `config:` prefixes. Repository manifests use four fields: name, URL, destination, platform. These are trusted repository configuration, not untrusted input; do not use traversal paths or overlapping destinations.

Only managed files/directories are linked, never all of `~/.config`, `~/.ssh` or `~/.oh-my-zsh`. SSH private keys are never managed. LazyGit's configuration uses its macOS Application Support location on macOS and its XDG location on Linux. Ghostty configuration is shared; installing Ghostty itself on Linux is manual. A Nerd Font is needed for the configured icons.

Zsh loads optional integrations only when installed, supports older distribution versions of fzf, and limits macOS DNS commands to macOS. Existing NVM/RVM installations are loaded when present but are not installed here. Add machine-specific settings to `$XDG_CONFIG_HOME/zsh/local.zsh`; this file is not managed by the repository.

## Migrating from Mackup

1. Commit or save any local configuration changes before migrating.
2. Run `./scripts/dotfiles plan` and inspect conflicts. Existing correct Mackup-created links remain valid.
3. Run `./scripts/dotfiles install`, or use `--backup` after reviewing conflicts. In particular, an existing Neovim directory must be the expected Git checkout or be moved/backed up.
4. Run `./scripts/dotfiles check` and review the new shell/editor configuration before removing old data.
5. Optionally remove the old `~/.mackup.cfg` and `~/.mackup` symlinks and uninstall Mackup yourself. The installer does not delete legacy files or uninstall packages.

Do not run `mackup restore` or `mackup uninstall` after migration: they can interfere with the newly managed destinations. The old `make backup` workflow is no longer needed: managed configuration is edited through its links and versioned in this repository. Conflict backups are separate from version control.
