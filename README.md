# dots

Personal NixOS + home-manager flake. Single source of truth for system config, dotfiles, dev shells, and theming. Currently configured for one host (`laptop`), with planned multi-host support (see `docs/multi-host-refactor.md`).

![screenshot](https://github.com/JPDye/dots/blob/main/sc2.png)
![screenshot](https://github.com/JPDye/dots/blob/main/sc1.png)

---

## Quick start

```nu
# system rebuild (NixOS only) — applies hosts/laptop/configuration.nix
sudo nixos-rebuild switch --flake ~/.config/nix#laptop

# user environment (home-manager) — applies home.nix + all modules
nh home switch ~/.config/nix

# or, without nh:
nix run home-manager/master -- switch -b backup --flake ~/.config/nix#laptop
```

`-b backup` tells home-manager to back up any pre-existing files it would otherwise refuse to overwrite (e.g. an existing `~/.config/niri/config.kdl`).

---

## Layout

```
.
├── flake.nix                 # inputs, overlays, hosts, homes, templates, devShell
├── home.nix                  # shared home-manager config (packages + module imports)
├── hosts/
│   └── laptop/               # NixOS host: configuration.nix, hardware-configuration.nix
├── modules/                  # home-manager modules, one per program/concern
│   ├── shell/                # aliases, cli-tools, integrations, nushell + scaffolds
│   ├── starship/             # prompt (nix module + standalone toml)
│   └── *.nix                 # one file per app/desktop component
├── templates/                # `nix flake init -t` targets: rust, python, go
├── fonts/                    # local flake exposing Berkeley Mono + IoskeleyMono
├── wallpapers/               # background images (halls.png is the default)
├── shaders/                  # cursor_warp.glsl (used by ghostty)
├── niri/config.kdl           # niri WM config in KDL (mirror of modules/niri.nix output)
└── docs/multi-host-refactor.md
```

---

## flake.nix at a glance

**Inputs:** `nixpkgs` (unstable), `home-manager`, `stylix`, `nixcord`, `claude-code`, `spicetify-nix`, `textfox`, `firefox-addons`, `niri`, `nixgl`, `helix`, `git-hooks`, plus a local `myFonts` flake under `./fonts`.

**Overlays:** niri, nixGL, firefox-addons.

**Outputs:**
- `nixosConfigurations.laptop` — the only NixOS host.
- `homeConfigurations.{arch,laptop}` — built via a `mkHome` helper that imports `home.nix` plus stylix/nixcord/niri home modules. The `arch` entry exists for using this flake standalone on a non-NixOS machine; only `laptop` has a matching system config.
- `templates.{rust,python,go}` — for `nix flake init -t .#<lang>`.
- `devShells.x86_64-linux.default` — pre-commit env (nixpkgs-fmt, deadnix, statix).
- `checks.x86_64-linux.pre-commit` — runs the same hooks via `git-hooks.nix`.

**Substituters declared in `nixConfig`:** helix.cachix.org, niri.cachix.org. These are only honored if the system trusts them — see `nix.settings.substituters` / `trusted-public-keys` in `hosts/laptop/configuration.nix`.

---

## hosts/laptop/configuration.nix

NixOS-side config. Highlights:

- **User:** `jd`, shell `nushell`, in `wheel`, `networkmanager`, `wireshark`.
- **Boot:** systemd-boot + EFI.
- **Networking:** NetworkManager, hostname `jd-nix`, DNS `1.1.1.1`/`8.8.8.8`, firewall opens UDP 53/41641/51820 (DNS, Tailscale, WireGuard).
- **Locale:** `en_GB.UTF-8`, `Europe/London`, UK keymap.
- **Services:** `tailscale` (client routing), `tlp` (AC perf / battery powersave 0–20%, charge thresholds 40–80%), `upower` (hibernate at 5%), `pipewire` (with PulseAudio compat + 32-bit ALSA), `blueman`, `niri`, `dbus` with portals (wlr/gtk/gnome), `wireshark` (CLI), `docker` (rootless) and `podman`.
- **Hardware:** AMD CPU (`kvm-amd`, microcode), OpenGL + 32-bit, Bluetooth on at boot.
- **Caches:** `cache.nixos.org`, `helix.cachix.org`, `niri.cachix.org` configured system-wide so non-trusted users can use them.
- **System fonts:** IoskeleyMono Nerd Font (default mono/serif/sans), Fira Code Nerd Font Mono, Lora, Font Awesome, Input Fonts.

---

## home.nix

Shared user config. Imports every file under `modules/` plus three third-party home modules (`spicetify-nix`, `textfox`, `nixcord`).

**Top-level packages** (things not large enough to deserve a module):

| Category | Packages |
|----------|----------|
| Niri/Wayland glue | `xwayland-satellite-stable`, `swaybg` |
| Browsers / comms / media | `chromium`, `spotify`, `ffmpeg`, `foliate`, `wireshark-qt` |
| Games / 3D | `steam`, `orca-slicer` |
| VPN / network | `wireguard-tools`, `protonvpn-gui` |
| Audio / display | `pavucontrol`, `brightnessctl` |
| Build | `sccache` |
| CLI | `bottom`, `hyperfine`, `unzip`, `tree` |
| Dev | `claude-code` (from flake input) |

**Session env:** `RUSTC_WRAPPER=sccache`. `PATH` extended with `~/.apps`, `/home/linuxbrew/.linuxbrew/bin`, `~/eww/target/release`.

> Note: `spotify` here conflicts with `programs.spicetify` (both write `share/spotify/spotify`). If you re-enable spicetify, drop the `spotify` package from `home.nix`.

---

## Modules

One module per program. All live under `modules/`. Each is imported by `home.nix`.

### Theming

| Module | What it does |
|--------|--------------|
| `theme.nix` | Shared color palette + font name + border tokens. Exposed via `_module.args` so other modules can `inherit (specialArgs) colors monoFont`. Gruvbox-dark-ish: `bg0=1c1c1c`, `fg0=fbf1c7`, accents `red af5f5f`, `green 87875f`, `yellow afa45f`, `orange af875f`, `blue 87afaf`, `pink af8787`. |
| `stylix.nix` | Base16 theming via [stylix]. Scheme: gruvbox-dark-hard, overridden with `theme.nix` colors. Wallpaper: `wallpapers/book.jpg`. Cursor: Bibata-Original-Amber 16px. Font sizes 14px. Disables stylix targets that have hand-rolled styling: firefox, spicetify, zellij, tofi, mako. Enables ghostty. |
| `fonts.nix` | Installs Nerd Fonts (fira-code, droid-sans-mono, symbols-only), Cascadia Code, Helvetica Neue LT Std, Siji, plus Berkeley Mono and IoskeleyMono from the local `fonts/` flake. Sets fontconfig fallback chain. |

### Desktop / Wayland

| Module | Notes |
|--------|-------|
| `niri.nix` | Niri compositor config (declarative). Defines outputs (eDP-1, HDMI-A-1), input (UK keymap, focus-follows-mouse), 24px gaps, 2px red active border, no CSD, rounded corners on all windows, floating rules for dialogs/blueman/pavucontrol, full-width opacity for Firefox/Spotify/Slack, layer rules placing wallpaper + eww in the backdrop. Also writes `niri/config.kdl` for reference/debugging. |
| `fuzzel.nix` | App launcher. 5 lines, no icons, Berkeley Mono Variable 11px, red border, orange prompt. Also configures `programs.tofi` as an alternative bottom-bar launcher. |
| `mako.nix` | Notification daemon. 4s timeout, red border, bg0 background. |
| `eww.nix` | Live-edits `~/.config/nix/eww/` (symlinked, not copied). Two systemd user services: `eww` daemon and `eww-powermenu` running `~/.config/nix/eww/powermenu.nu`. |
| `swww.nix` | Wallpaper daemon as a systemd user service. Started by niri at session-start with `swww img wallpapers/halls.png`. |

### Terminals

| Module | Notes |
|--------|-------|
| `alacritty.nix` | Shell `nushell`, beam cursor, auto-copy selection, 5px padding. |
| `ghostty.nix` | Default command `zellij`. Bar cursor, blinking, custom shader `shaders/cursor_warp.glsl`. 16-color palette mapped to `theme.nix`. Close confirmation off. |
| `zellij.nix` | Default shell `nushell`, compact layout, no frames, no startup tips. Unbinds `Ctrl+h` (so it falls through to nushell's BackspaceWord). Custom theme using palette colors. |

### Shell

`modules/shell/default.nix` aggregates four files. The shared aliases live in `aliases.nix` and are exported via `_module.args.shellAliases` so any shell module can pick them up.

| File | What it does |
|------|--------------|
| `aliases.nix` | `vi`/`vim`/`nano` → `hx`, `cat` → `bat`, `grep` → `rg`, `du` → `dust`, `ps` → `procs`, `sed` → `sd`, `ls` → `eza -1`, `tree` → `eza --tree --git-ignore`. |
| `cli-tools.nix` | Installs the modern Unix toolkit: `ripgrep`, `fd`, `dust`, `procs`, `sd`, `jq`, `tokei`, `glow`, `tealdeer` (with auto-update). |
| `integrations.nix` | Configures `zoxide` (`cd`/`cdi`), `carapace` completions, `atuin` history (`Ctrl+r`), `direnv` + `nix-direnv` (silent), `bat` (with `less -FR` pager), `eza` (icons + git status). |
| `nushell.nix` | Enables `programs.nushell`. `EDITOR=hx`, no banner, fuzzy completions, `Ctrl+h`=BackspaceWord. Sources `~/.config/nushell/welcome.nu` and `scaffolds.nu`. |
| `nushell/welcome.nu` | Width-aware fastfetch banner shown at shell start. |
| `nushell/scaffolds.nu` | `init-rust` / `init-python` / `init-go` — copy a template into cwd, `git init`, stage files, `direnv allow`. |
| `README.md` | Per-domain notes for the shell module. |

### Prompt / sysinfo

| Module | Notes |
|--------|-------|
| `starship/starship.nix` | Two-line prompt with box-drawing connectors. Sections: user (red), dir truncated to last 3 (orange), git branch + status (yellow, custom symbols for modified/untracked/ahead/behind/diverged/stashed), 24h time (green). Module rendered into `~/.config/starship.toml` by home-manager. |
| `starship/starship.toml` | Hand-written equivalent (kept for reference; the `.nix` version is the one applied). |
| `fastfetch.nix` | Colored NixOS logo + date/time, WM, terminal, editor, media player, CPU/mem/disk with percent bars. |

### Dev

| Module | Notes |
|--------|-------|
| `git.nix` | User: Joe Dye, `jpzh.dye@gmail.com`. Delta enabled (line numbers, navigate, hyperlinks). Aliases: `st`, `co`, `sw`, `br`, `lg` (decorated graph log), `last`, `unstage`, `amend`. Sensible defaults: `pull.rebase=true`, `push.autoSetupRemote=true`, `rebase.autoStash=true`, `merge.conflictStyle=zdiff3`, `diff.algorithm=histogram`, `init.defaultBranch=main`. |
| `helix.nix` | Editor (default `EDITOR`), built from the `helix` flake input (latest master). LSP servers: `nixd`, `taplo`, `marksman`, `tinymist`, `harper-ls`, `typos-lsp`, `bash-language-server`, `yaml-language-server`, `dockerfile-language-server-nodejs`, `basedpyright`, `ruff`, plus `rust-analyzer` (clippy pedantic, fill-arg snippets, hidden trivial inlay hints). Custom theme `stylix-jumps`. Per-language config for Rust/Nix/TOML/Typst/Markdown/Bash/YAML/Dockerfile/Python with auto-format on save. `nixd` is wired to read this flake's `homeConfigurations.${hostname}.options` for option completion. |
| `nh.nix` | The `nh` nix-helper. `flake = ~/.config/nix`. Auto-cleans generations: keep last 5, plus everything from past 7 days. Enables `nix-output-monitor`. |

### Apps

| Module | Notes |
|--------|-------|
| `firefox.nix` | Profile `jd`. Theme: TextFox (minimal text-style chrome) using palette colors and Berkeley Mono Variable. Adds bang-style search shortcuts: `@rs` (Rust stdlib), `@crs` (lib.rs), `@np` (nix packages), `@hm` (home-manager options). Installs ~30 extensions: Bitwarden, uBlock Origin, Privacy Badger, ClearURLs, I-Still-Don't-Care-About-Cookies, SponsorBlock, Return YouTube Dislike, YouTube Shorts Block, LanguageTool, Dark Reader, Tabliss, FoxyProxy, Sidebery, etc. |
| `spicetify.nix` | Spotify with the `text` theme and a custom color scheme matching the rest of the system. |
| `nixcord.nix` | Discord with the `system24` Vencord theme (gruvbox-material flavor). |

---

## Keybindings

### Niri (compositor)

`Mod` = Super.

| Group | Bind | Action |
|------:|------|--------|
| Apps | `Mod+Space` / `Mod+Return` / `Mod+R` | Firefox / alacritty+zellij / fuzzel |
| Window | `Mod+Q` / `Mod+Shift+O` / `Mod+O` | close / toggle opacity / overview |
| Focus | `Mod+H/J/K/L` | focus column or window |
| Move | `Mod+Shift+H/J/K/L` | move column or window |
| Monitor | `Mod+Ctrl+H/J/K/L` (+ `Shift` to move) | focus / move window between outputs |
| Workspace | `Mod+1..4` (+ `Ctrl` to move) | focus / move to workspace |
| Columns | `Mod+,` / `Mod+.` | consume into / expel from column |
| Sizing | `Mod+G` / `Mod+Shift+G` / `Mod+C` / `Mod±=/-` | preset width / preset height / center / resize 10% |
| Fullscreen | `Mod+F` / `Mod+Shift+F` / `Mod+Ctrl+F` | maximize column / fullscreen / reset height |
| Screenshot | `Mod+P` / `Ctrl+Print` / `Alt+Print` | region / screen / window |
| System | `Mod+Shift+E` or `Ctrl+Alt+Del` / `Mod+Shift+P` | quit / power off monitors |

### Shell

- `Ctrl+h` — backspace word (insert mode).
- `Ctrl+r` — atuin fuzzy history search.
- `cd <fragment>` — zoxide jump; `cdi` for interactive.

### Helix

Uses upstream defaults plus the jump-label alphabet `asdfghjklweruio`. Auto-format on save is on for every configured language.

---

## Templates

`nix flake init -t ~/.config/nix#<lang>` drops a `flake.nix`, `flake.lock`, and `.envrc` into the current directory. After `direnv allow`, the dev shell auto-activates on `cd`.

| Template | Provides |
|----------|----------|
| `rust` | Rust 1.90.0 (rust-src, rust-analyzer, clippy, rustfmt) + mold + clang + sccache as `RUSTC_WRAPPER` (with `CARGO_INCREMENTAL=0`). Dev tools: `bacon`, `cargo-nextest`, `cargo-llvm-cov`, `cargo-udeps`, `cargo-machete`, `cargo-flamegraph`. |
| `python` | Python 3.13, `uv`, `ruff`, `basedpyright`. |
| `go` | `go`, `gopls`, `delve`, `golangci-lint`, `gotools`. |

The nushell scaffolds (`init-rust`, `init-python`, `init-go`) wrap `nix flake init -t`, run `git init` if needed, stage the new files, and `direnv allow` in one go.

---

## Adding things

### A new host

1. `cp -r hosts/laptop hosts/<name>` and edit `configuration.nix` + `hardware-configuration.nix`.
2. In `flake.nix`, add a `nixosConfigurations.<name>` entry next to `laptop`.
3. If you also want a home-manager profile for it, add `homeConfigurations.<name> = mkHome "<name>"`.
4. `sudo nixos-rebuild switch --flake .#<name>` and `nh home switch . -- --flake .#<name>`.

The planned multi-host refactor (`docs/multi-host-refactor.md`) introduces per-module `dotfiles.<name>.enable` toggles and groups modules by domain. Worth a read before adding a non-NixOS host (e.g. Arch).

### A new module

1. Create `modules/<name>.nix`. Take `colors`, `monoFont`, etc. via function args (they come from `theme.nix` via `_module.args`).
2. Import it in `home.nix`.
3. If the module installs packages or a program, prefer the `programs.<x>` home-manager option over `home.packages` so config and binary stay together.
4. Run `nix flake check` (runs `nixpkgs-fmt`, `deadnix`, `statix`).
5. `nh home switch . -- --dry-activate` to preview, then drop `--dry-activate`.

---

## Updating

```nu
nix flake update                                         # bump all inputs
nix flake update nixpkgs helix niri                      # bump specific inputs
sudo nixos-rebuild switch --flake ~/.config/nix#laptop   # apply system
nh home switch ~/.config/nix                             # apply user
nh clean all                                             # gc, respecting nh.nix retention
```

---

## Troubleshooting

**`Command 'welcome' not found` in nushell startup.** The home-manager-symlinked `welcome.nu` resolves to a hashed nix-store name, so `use ~/.config/nushell/welcome.nu` registers a module under that hash. Fixed by `source`ing the file instead of `use`ing it (see `modules/shell/nushell.nix`).

**`ignoring untrusted substituter 'https://niri.cachix.org'`.** Substituters declared in `flake.nix#nixConfig` only apply if the user is trusted. Either run `sudo nixos-rebuild switch` to pick up the system-wide caches in `hosts/laptop/configuration.nix`, or add your user to `nix.settings.trusted-users`.

**`Existing file '...' would be clobbered`.** Pass `-b backup` to home-manager (or set `home-manager.backupFileExtension` if invoking via the NixOS module). The conflicting file becomes `<file>.backup`.

**`pkgs.buildEnv error: two given paths contain a conflicting subpath`.** Two packages install to the same path. Common offender: `spotify` + `programs.spicetify` (both write `share/spotify/spotify`) — drop the bare `spotify` package.

**`error: executing 'git': No such file or directory` during niri build.** Harmless. Nix is trying to look up HEAD refs for git-source Cargo deps; it falls back to `master`. Only matters if the build fails for another reason.
