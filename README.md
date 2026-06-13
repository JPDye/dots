# dots

Personal NixOS + home-manager flake. Single source of truth for system config, dotfiles, dev shells, and theming. Works on two hosts:

- **`laptop-nix`** — NixOS box (`hosts/laptop-nix/configuration.nix` + matching home overlay).
- **`desktop-arch`** — standalone home-manager on Arch Linux. Same modules, GPU-using GUI apps wrapped with nixGL.

![screenshot](https://github.com/JPDye/dots/blob/main/sc2.png)
![screenshot](https://github.com/JPDye/dots/blob/main/sc1.png)

---

## Setup on a new machine

### Prerequisites (any host)

1. **Install nix** (multi-user, daemon-mode).
   - Arch: `sudo pacman -S nix && sudo systemctl enable --now nix-daemon`
   - Fedora / Debian / etc.: [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer)
   - NixOS: already there.
2. **Enable flakes** if the installer didn't already:
   ```
   # /etc/nix/nix.conf or ~/.config/nix/nix.conf
   experimental-features = nix-command flakes
   ```
3. **Trust your user** so per-flake substituters (helix.cachix, niri.cachix) and `trusted-public-keys` are honoured. Otherwise `direnv reload` and every `nix` command spam warnings about ignoring the flake's `nixConfig`:
   ```bash
   echo 'trusted-users = root @wheel' | sudo tee -a /etc/nix/nix.conf
   sudo systemctl restart nix-daemon
   ```
4. **Clone the repo**:
   ```bash
   git clone <url> ~/.config/nix
   cd ~/.config/nix
   ```

### Path A: NixOS host

```bash
# Bootstrap a host folder (or fork hosts/laptop-nix as a starting point)
mkdir hosts/<name>
cp hosts/laptop-nix/{configuration,hardware-configuration}.nix hosts/<name>/   # then edit
echo "_: { programs.niri.settings.outputs = { /* your monitors */ }; }" > hosts/<name>/home.nix

# Wire up the flake (edit flake.nix):
#   nixosConfigurations.<name> = ...   # mirror the laptop-nix block
#   homeConfigurations.<name>  = mkHome "<name>";

# Apply:
sudo nixos-rebuild switch --flake .#<name>
home-manager switch -b backup --flake ".#<name>"
```

### Path B: Standalone home-manager (Arch / Fedora / Debian / etc.)

```bash
# Get the home-manager CLI:
nix run nixpkgs#home-manager -- init --switch  # or skip if already installed

# Create a per-host overlay (only the unavoidable bits — monitors and, on
# non-NixOS, a nixGL wrap function for GUI apps). See hosts/desktop-arch/home.nix
# as a working example.
mkdir hosts/<name>
$EDITOR hosts/<name>/home.nix

# Wire up the flake (edit flake.nix):
#   homeConfigurations.<name> = mkHome "<name>";

# Apply:
home-manager switch -b backup --flake ".#<name>"
```

If the OS doesn't supply OpenGL libs at the standard nixpkgs paths (most non-NixOS distros), set `dotfiles.wrapGL` in the host overlay so GUI apps run under nixGL — `hosts/desktop-arch/home.nix` shows the pattern with the Mesa variant (`nixGLIntel`, also covers AMD).

### Daily use

```nu
# Pull and apply
git pull
home-manager switch --flake ".#<host>"     # or `nh home switch <path>`
sudo nixos-rebuild switch --flake .#<host> # NixOS only

# Update flake inputs
nix flake update                            # all inputs
nix flake update helix niri                 # just these

# Garbage-collect old generations (respects nh.nix retention: keep 5, last 7d)
nh clean all
```

Notes:
- `-b backup` tells home-manager to back up any pre-existing dotfile it would otherwise refuse to overwrite (becomes `<file>.backup`).
- Run from the flake directory (`~/.config/nix`) so `.` resolves correctly. In nushell, quote any flake URL containing `#` (`".#<host>"`) — `#` is a comment delimiter otherwise.
- `nh home switch -c <host>` resolves to `homeConfigurations.<user>@<host>` first, which doesn't match this flake's plain-host attribute names. Use `home-manager switch --flake .#<host>` directly.

---

## Layout

```
.
├── flake.nix                 # inputs, overlays, hosts, homes, templates, devShell
├── home.nix                  # shared home-manager config; imports domain folders + per-host overlay
├── hosts/
│   ├── laptop-nix/
│   │   ├── configuration.nix      # NixOS system config
│   │   ├── hardware-configuration.nix
│   │   └── home.nix               # per-host HM overlay (laptop monitors, unwrapped GUI apps)
│   └── desktop-arch/
│       └── home.nix               # per-host HM overlay (Arch monitors, nixGL-wrapped GUI apps)
├── modules/                  # home-manager modules, grouped by domain
│   ├── theming/              # theme tokens, stylix, fonts
│   ├── desktop/              # niri, fuzzel, mako, eww, swww, swayosd, cliphist, polkit
│   ├── terminals/            # ghostty, zellij
│   ├── shell/                # aliases, cli-tools, integrations, nushell, starship, fastfetch
│   ├── dev/                  # git, helix, nh
│   └── apps/                 # firefox, spicetify, nixcord
├── templates/                # `nix flake init -t` targets: rust, python, go, typst
├── fonts/                    # local flake exposing IoskeleyMono
├── wallpapers/               # background images (socrates.jpg is the default; its blur is derived at build time)
└── shaders/                  # cursor_warp.glsl (used by ghostty)
```

---

## How multi-host works

Three pieces:

1. **`mkHome` in `flake.nix`** keys a home configuration by hostname and threads `inputs`, `hostname`, and `system` through `extraSpecialArgs`. Both `homeConfigurations.desktop-arch` and `homeConfigurations.laptop-nix` are built from the same module list.
2. **Per-module toggles**: every module under `modules/` exposes `dotfiles.<domain>.<name>.enable` (default `true`). To skip something on a host, set its toggle `false` in that host's overlay. Two exceptions stay unwrapped because they only set `_module.args` for other modules: `theming/theme.nix` and `shell/aliases.nix`.
3. **Per-host overlays at `hosts/<host>/home.nix`**: the only place per-host divergence lives. Includes things like:
   - host-specific `home.packages` (laptop installs GUI apps unwrapped; Arch wraps them via `nixGL`).
   - `programs.niri.settings.outputs` (different monitors on each box).
   - any `lib.mkForce` overrides for shared bindings (e.g. Arch overrides `Mod+Return` to spawn `nixGL ghostty`).

Hardcoded paths are written against `inputs.self.outPath` so the flake works regardless of where it's checked out — except `eww` which uses `mkOutOfStoreSymlink` and points at `~/.config/nix/eww` so the user can hand-edit eww files without rebuilding.

---

## flake.nix at a glance

**Inputs:** `nixpkgs` (unstable), `home-manager`, `stylix`, `nixcord`, `claude-code`, `spicetify-nix`, `textfox`, `firefox-addons`, `niri`, `nixgl`, `nix-index-database`, `helix`, `git-hooks`, `nixos-hardware`, plus a local `myFonts` flake under `./fonts`.

**Overlays:** niri, nixGL, firefox-addons.

**Outputs:**
- `nixosConfigurations.laptop-nix` — the only NixOS host.
- `homeConfigurations.{desktop-arch,laptop-nix}` — built via `mkHome`. Both import the same domain folders + the host's `hosts/<host>/home.nix` overlay. The `desktop-arch` entry is the standalone-HM target on Arch Linux.
- `templates.{rust,python,go,typst}` — for `nix flake init -t .#<lang>`.
- `devShells.x86_64-linux.default` — pre-commit env (nixfmt, deadnix, statix, typos).
- `checks.x86_64-linux.{pre-commit,caches-in-sync,nixos-<host>,home-<host>}` — `pre-commit` runs the hooks via `git-hooks.nix`; `caches-in-sync` fails if the `nixConfig` cache literals drift from `caches.nix`; the per-host entries build each host's NixOS toplevel / HM activation so `nix flake check` catches eval/build breakage before a `switch`.
- `hmOptions.<host>` — per-host home-manager option trees, consumed by `nixd` for option completion.

**Substituters declared in `nixConfig`:** helix.cachix.org, niri.cachix.org. Only honoured if the system trusts them — see `nix.settings.substituters` / `trusted-public-keys` in `hosts/laptop-nix/configuration.nix`.

---

## hosts/laptop-nix/configuration.nix

NixOS-side config. Highlights:

- **User:** `jd`, shell `nushell`, in `wheel`, `networkmanager`, `wireshark`.
- **Boot:** systemd-boot + EFI.
- **Networking:** NetworkManager (DNS forced to `none` so static `nameservers` win), hostname `laptop-nix`, DNS `1.1.1.1`/`1.0.0.1` (Cloudflare), firewall opens UDP 41641/51820 (Tailscale, WireGuard).
- **Locale:** `en_GB.UTF-8`, `Europe/London`, UK keymap.
- **Services:** `tailscale`, `tlp` (AC perf / battery powersave 0–20%, charge thresholds 40–80%), `upower` (hibernate at 5%), `pipewire` (with PulseAudio compat + 32-bit ALSA), `blueman`, `niri`, `dbus` with portals (wlr/gtk/gnome), `wireshark` (CLI), `docker` (rootless) and `podman`.
- **Hardware:** AMD CPU (`kvm-amd`, microcode), OpenGL + 32-bit, Bluetooth on at boot.
- **Caches:** `cache.nixos.org`, `helix.cachix.org`, `niri.cachix.org` configured system-wide so non-trusted users can use them.
- **System fonts:** IoskeleyMono Nerd Font (default mono/serif/sans), Fira Code Nerd Font Mono, Lora, Font Awesome, Input Fonts.

On Arch the equivalent is whatever `pacman` / `systemctl --user` arrangement you already have — this flake does not try to manage system-level services on non-NixOS hosts.

---

## home.nix and per-host overlays

`home.nix` is the shared base. It imports every domain folder under `modules/`, three third-party HM modules (`spicetify-nix`, `textfox` — `nixcord` is loaded via `mkHome`), and the active host's `hosts/${hostname}/home.nix`.

**Shared `home.packages`** — CLI tools and lightweight bits, nothing GPU-using:

| Category | Packages |
|----------|----------|
| Audio / display | `pavucontrol`, `brightnessctl` |
| Wayland helpers | `hyprpicker`, `libnotify` |
| Networking | `wireguard-tools` |
| CLI | `bottom`, `hyperfine`, `unzip`, `tree`, `ffmpeg` |
| Dev | `claude-code` (from flake input) |

**Shared `home.sessionPath`:** just `~/.apps`.

**`hosts/laptop-nix/home.nix`** adds:
- `~/eww/target/release` to `sessionPath`.
- GUI/GPU packages installed straight from nixpkgs: `xwayland-satellite-stable`, `swaybg`, `chromium`, `foliate`, `wireshark`, `obsidian`, `gpu-screen-recorder-gtk`, `steam`, `orca-slicer`, `proton-vpn`.
- `programs.niri.settings.outputs` for `eDP-1` and `HDMI-A-1`.

**`hosts/desktop-arch/home.nix`** adds:
- Same `~/eww/target/release` `sessionPath` entry.
- The same GUI list, but each package run through a `wrapGL` helper that wraps every binary in `bin/` with `nixGLIntel` (Mesa-based, also covers AMD GPUs). `nixgl.nixGLIntel` itself is exposed so `nixGL <cmd>` is available ad-hoc.
- `programs.niri.settings.outputs` for `HDMI-A-1` (rotated 90°), `DP-10`, `DP-9`.
- `lib.mkForce` override for `Mod+Return` → `nixGL ghostty` so the editor terminal also goes through nixGL.

---

## Modules

Every module under `modules/` follows the same shape:

```nix
{ config, lib, ... }:
let
  cfg = config.dotfiles.<domain>.<name>;
in
{
  options.dotfiles.<domain>.<name>.enable =
    lib.mkEnableOption "<short description>" // { default = true; };

  config = lib.mkIf cfg.enable {
    # body
  };
}
```

The two exceptions are `theming/theme.nix` and `shell/aliases.nix`, which only publish `_module.args` for siblings to consume and aren't toggleable.

### Theming (`modules/theming/`)

| Module | What it does |
|--------|--------------|
| `theme.nix` | Shared colour palette + font name + border tokens. Exposed via `_module.args` so siblings can `inherit (specialArgs) colors monoFont border-style`. Gruvbox-dark-ish: `bg0=1c1c1c`, `fg0=fbf1c7`, accents `red af5f5f`, `green 87875f`, `yellow afa45f`, `orange af875f`, `blue 87afaf`, `pink af8787`. |
| `stylix.nix` | Base16 theming via [stylix]. Scheme: gruvbox-dark-hard, overridden with `theme.nix` colours. Wallpaper: `dotfiles.theme.wallpaper`. Cursor: Bibata-Original-Amber 16px. Font sizes 14px. Disables stylix targets that have hand-rolled styling (firefox, spicetify, zellij, mako) — but only when those toggles are on, so disabling firefox via toggle no longer leaves stylix referencing a missing program. |
| `wallpaper.nix` | `dotfiles.theme.wallpaper` — single source of truth for the wallpaper image (default `wallpapers/socrates.jpg`), consumed by awww, stylix and hyprlock. `dotfiles.theme.wallpaperBlurred` defaults to a build-time ImageMagick gaussian blur (sigma 20) of it, shown by `swaybg` in the niri backdrop; set it to a file for a hand-made blur. |
| `fonts.nix` | Installs Nerd Fonts (fira-code, droid-sans-mono, symbols-only), Cascadia Code, Helvetica Neue LT Std, Siji, plus IoskeleyMono from the local `fonts/` flake. Sets fontconfig fallback chain. |

### Desktop / Wayland (`modules/desktop/`)

| Module | Notes |
|--------|-------|
| `niri/` | Niri compositor config, split across `default.nix`, `binds.nix`, `layout.nix`, `window-rules.nix`, `animations.nix`, `spawn.nix`. Holds everything that's the same on every host: input (UK keymap, focus-follows-mouse), 8px gaps, 1px red active border, no CSD, layer rules placing wallpaper + eww in the backdrop, every binding, custom shaders for window-open/close/resize animations, startup spawns for `xwayland-satellite`, `mako`, `awww`, `swaybg`. **Outputs are not here** — each host's overlay defines them. |
| `fuzzel.nix` | App launcher. 5 lines, no icons, monoFont 11px, red border, orange prompt. |
| `mako.nix` | Notification daemon. 4s timeout, red border, bg0 background. |
| `eww.nix` | Live-edits `~/.config/nix/eww/` (symlinked, not copied — `mkOutOfStoreSymlink` keeps source-of-truth on disk). Two systemd user services: `eww` daemon and `eww-powermenu` running `~/.config/nix/eww/powermenu.nu`. |
| `swww.nix` | `awww` wallpaper daemon as a systemd user service. Started by niri at session-start. |
| `swayosd.nix` | On-screen volume/brightness/caps-lock indicator. Triggered by niri `XF86Audio*`/`XF86MonBrightness*` binds. |
| `cliphist.nix` | Wayland clipboard history. Browsed via the two-mode picker in binds.nix: `Mod+V` lists text entries in fuzzel (dense small font, ids hidden via `--with-nth`, searchable `[label]` prefixes via `Alt+1`, `Alt+2` deletes an entry, `Alt+3` purges all unlabelled); `Mod+Shift+V` decodes the image entries into `~/.cache/cliphist-images` and opens them as an **nsxiv** thumbnail grid (X11 via xwayland-satellite, floated by a window rule) — `Q` copies the focused image. Labels live in `~/.local/share/cliphist-labels`, GC'd with the history. |
| `polkit.nix` | `polkit-gnome-authentication-agent-1` as a systemd user service. |
| `udiskie.nix` | Removable-media automounter (USB drives mount on plug-in, notifications via mako, no tray). Talks to the system `udisks2` daemon — enabled in `modules/system/desktop.nix` on NixOS, `pacman -S udisks2` on Arch. |

### Terminals (`modules/terminals/`)

| Module | Notes |
|--------|-------|
| `ghostty.nix` | Default command `zellij`. Bar cursor, blinking, custom shader `shaders/cursor_warp.glsl`. 16-colour palette mapped to `theme.nix`. Close confirmation off. On Arch the binary itself isn't wrapped with nixGL — niri spawns it via `nixGL ghostty` instead. |
| `zellij.nix` | Default shell `nushell`, compact layout, no frames, no startup tips. Unbinds `Ctrl+h` (so it falls through to nushell's BackspaceWord). Custom theme using palette colours. |

### Shell (`modules/shell/`)

`default.nix` aggregates the rest. Shared aliases live in `aliases.nix` and are exported via `_module.args.shellAliases` so any shell module can pick them up.

| File | What it does |
|------|--------------|
| `aliases.nix` | `vi`/`vim`/`nano` → `hx`, `cat` → `bat`, `grep` → `rg`, `du` → `dust`, `ps` → `procs`, `sed` → `sd`, `ls` → `eza -1`, `tree` → `eza --tree --git-ignore`. |
| `cli-tools.nix` | Modern Unix toolkit: `ripgrep`, `fd`, `dust`, `procs`, `sd`, `jq`, `tokei`, `glow`, `wl-clipboard`, `tealdeer` (with auto-update). |
| `integrations.nix` | Configures `zoxide` (`cd`/`cdi`), `carapace` completions, `atuin` history (`Ctrl+r`), `direnv` + `nix-direnv` (silent), `bat` (with `less -FR` pager), `eza` (icons + git status). |
| `nushell.nix` | Enables `programs.nushell`. `EDITOR=hx`, no banner, fuzzy completions, `Ctrl+h`=BackspaceWord. Sources `~/.config/nushell/welcome.nu` and `scaffolds.nu`. |
| `starship.nix` | Two-line prompt with box-drawing connectors. Sections: user (red), dir truncated to last 3 (orange), git branch + status (yellow, custom symbols for modified/untracked/ahead/behind/diverged/stashed), 24h time (green). |
| `fastfetch.nix` | Coloured NixOS logo + date/time, WM, terminal, editor, media player, CPU/mem/disk with percent bars. |
| `nushell/welcome.nu` | Width-aware fastfetch banner shown at shell start. |
| `nushell/scaffolds.nu` | `init-rust` / `init-python` / `init-go` — copy a template into cwd, `git init`, stage files, `direnv allow`. |

### Dev (`modules/dev/`)

| Module | Notes |
|--------|-------|
| `git.nix` | User: Joe, `jpzh.dye@gmail.com`. Delta enabled (line numbers, navigate, hyperlinks). Aliases: `st`, `co`, `sw`, `br`, `lg` (decorated graph log), `last`, `unstage`, `amend`. Sensible defaults: `pull.rebase=true`, `push.autoSetupRemote=true`, `rebase.autoStash=true`, `merge.conflictStyle=zdiff3`, `diff.algorithm=histogram`, `init.defaultBranch=main`. |
| `helix/` | Editor (default `EDITOR`), built from the `helix` flake input (latest master); split across `default.nix`, `editor.nix`, `languages.nix`, `themes.nix`. LSP servers: `nixd`, `taplo`, `marksman`, `tinymist`, `harper-ls`, `typos-lsp`, `bash-language-server`, `yaml-language-server`, `dockerfile-language-server-nodejs`, `basedpyright`, `ruff`, plus `rust-analyzer` (clippy pedantic, fill-arg snippets, hidden trivial inlay hints). Custom theme `stylix-jumps`. Per-language config for Rust/Nix/TOML/Typst/Markdown/Bash/YAML/Dockerfile/Python with auto-format on save. `nixd` is wired to `inputs.self`'s `homeConfigurations.${hostname}.options` for option completion (works regardless of where the flake is checked out). |
| `nh.nix` | The `nh` nix-helper. `flake = inputs.self.outPath` (a /nix/store path; pass an explicit path to `nh home switch` if you want it to operate on the live source). Auto-cleans generations: keep last 5, plus everything from past 7 days. Enables `nix-output-monitor`. |

### Apps (`modules/apps/`)

| Module | Notes |
|--------|-------|
| `firefox.nix` | Profile `jd`. Theme: TextFox (minimal text-style chrome) using palette colours and `monoFont` from `theme.nix`. Adds bang-style search shortcuts: `@rs` (Rust stdlib), `@crs` (lib.rs), `@np` (nix packages), `@hm` (home-manager options). Installs ~30 extensions: Bitwarden, uBlock Origin, Privacy Badger, ClearURLs, I-Still-Don't-Care-About-Cookies, SponsorBlock, Return YouTube Dislike, YouTube Shorts Block, LanguageTool, Dark Reader, Tabliss, FoxyProxy, Sidebery, etc. |
| `spicetify.nix` | Spotify with the `text` theme and a custom colour scheme matching the rest of the system. |
| `nixcord.nix` | Discord with the `system24` Vencord theme (gruvbox-material flavour). |

---

## Keybindings

### Niri (compositor)

`Mod` = Super. Niri is a **scrollable column-based** Wayland compositor — windows tile into vertical columns that scroll horizontally. There's no "tile/stack" toggle; movement is always relative to the column.

| Group | Bind | Action |
|------:|------|--------|
| Apps | `Mod+Space` | Firefox |
| | `Mod+Return` | ghostty (under nixGL on Arch) |
| | `Mod+R` | fuzzel app launcher |
| | `Mod+V` | clipboard history, text entries (fuzzel, dense). In-picker: `Alt+1` label · `Alt+2` delete entry · `Alt+3` purge all unlabelled |
| | `Mod+Shift+V` | clipboard history, images — nsxiv thumbnail grid; navigate, `Q` to copy the focused image |
| | `Mod+I` | hyprpicker → notify-send (pick a colour, copies hex) |
| Window | `Mod+Q` | close window |
| | `Ctrl+Q` | left unbound — passes through to the focused app (Helix binds it for typos; see below) |
| | `Mod+Shift+O` | toggle window-rule opacity |
| | `Mod+O` | toggle overview (zoomed-out workspace view) |
| Focus | `Mod+H/J/K/L` | focus column left / window down / window up / column right |
| | `Mod+Shift+WheelUp/Down` | focus column left / right (scroll alternative) |
| Move | `Mod+Shift+H/J/K/L` | move column or window in that direction |
| | `Mod+Ctrl+Shift+WheelUp/Down` | move column left / right |
| Monitor | `Mod+Ctrl+H/J/K/L` | focus other monitor |
| | `Mod+Shift+Ctrl+H/J/K/L` | move window to other monitor |
| Workspace | `Mod+1..4` | focus workspace 1–4 |
| | `Mod+Ctrl+1..4` | move window to workspace 1–4 |
| Column shape | `Mod+,` / `Mod+.` | consume window into column / expel out |
| | `Mod+G` / `Mod+Shift+G` | cycle preset column-width / window-height |
| | `Mod+C` | centre current column |
| | `Mod±=/-` | grow/shrink column by 10% |
| | `Mod+Shift±=/-` | grow/shrink window height by 10% |
| Fullscreen | `Mod+F` / `Mod+Shift+F` / `Mod+Ctrl+F` | maximise column / fullscreen window / reset height |
| Screenshot | `Mod+P` / `Ctrl+Print` / `Alt+Print` | region / whole screen / focused window |
| | `Print` | region → satty (annotate/redact) → clipboard + file |
| Clipboard image | `Mod+Shift+P` | clipboard image → satty → annotated image back to clipboard |
| | `Mod+Ctrl+P` | clipboard image → tesseract OCR → text in clipboard |
| Media | `XF86AudioRaiseVolume`/`Lower`/`Mute` | volume via swayosd (visual indicator) |
| | `XF86AudioMicMute` | mic mute toggle |
| | `XF86MonBrightnessUp`/`Down` | brightness via swayosd |
| Bar | `Mod+Shift+C` | reload eww via SIGUSR1 |
| System | `Mod+Shift+E` or `Ctrl+Alt+Del` | quit niri (with confirm dialog) |
| | `Mod+Ctrl+Shift+P` | power off monitors |

Definitions live in `modules/desktop/niri/` (shared, mostly `binds.nix`) plus host overrides in `hosts/<host>/home.nix` (e.g. Arch overrides `Mod+Return` to `nixGL ghostty`).

### Zellij (terminal multiplexer)

Default zellij modal bindings — press the prefix to enter a mode, then a single key:

| Mode | Prefix | Common keys |
|------|--------|-------------|
| Pane | `Ctrl+p` | `n` new / `x` close / `f` fullscreen / `h/j/k/l` focus |
| Tab | `Ctrl+t` | `n` new / `x` close / `r` rename / `1..9` jump |
| Resize | `Ctrl+n` | `h/j/k/l` shrink/grow |
| Scroll | `Ctrl+s` | `j/k` line / `Ctrl+u/d` half-page / `e` edit scrollback |
| Session | `Ctrl+o` | `d` detach / `w` switch session |

Plus, from this config: **mouse mode** is on (drag pane borders to resize) and **copy on select** is on (selecting in scroll mode auto-copies to the clipboard). `Ctrl+h` and `Ctrl+q` are unbound at the zellij level — `Ctrl+h` falls through to nushell's BackspaceWord, and `Ctrl+q` to the focused app (Helix's typos silence/restore). Quit zellij by exiting the shell or detaching with `Ctrl+o` then `d`.

### Helix (editor)

Upstream defaults apply — see `hx --tutor` for the full keymap. Customisations from `modules/dev/helix/`:

- `Ctrl+v` (normal mode) — toggle LSP inlay hints.
- `Ctrl+q` / `Ctrl+Shift+q` (normal mode) — silence / restore the typos-lsp spell checker in the current buffer (other language servers unaffected).
- `Enter` (normal mode) — `goto_word` (Easymotion-style: shows jump labels using the `asdfghjklweruio` alphabet, type a label to jump).
- `Space` mode — file picker (`f`), buffer picker (`b`), workspace symbol search (`s`), formatter (`=`), code action (`a`).
- Auto-format on save for every language with a configured formatter.
- Auto-save on focus-lost and after 3s idle.
- File-picker respects `~/.config/helix/ignore` (lists `target/`, `node_modules/`, `.direnv/`, `.venv/`, `__pycache__/`, etc.) so junk doesn't show up even outside git repos.

### Bacon (Rust auto-runner)

Default keys plus extras from `modules/dev/bacon.nix`:

| Key | Job |
|-----|-----|
| `c` | check |
| `t` | test |
| `n` | nextest (this config) |
| `v` | `cargo llvm-cov` (this config) |
| `Shift+v` | `cargo llvm-cov --html` (this config) |
| `r` | re-run current job |
| `q` / `Esc` | quit |

`bacon` (no args) starts in clippy mode. Per-project `bacon.toml` overrides anything here.

### Shell (nushell)

Nushell is the login shell. Pipelines carry structured data (tables, records, lists) instead of raw bytes — `ls | where size > 1mb | sort-by modified -r` works without `awk` or `cut`. The default external command is left as nushell-native; the toolkit below replaces or augments common Unix commands.

#### Keybindings

- `Ctrl+h` (insert mode) — backspace one word. Standard `Ctrl+w` is left to terminals/tmux/zellij where it has other meanings.
- `Ctrl+r` — open **atuin** fuzzy history search (TUI overlay).
- Tab — **carapace** completion menu, including subcommand and flag completion for ~1000 CLIs.

#### Directory navigation: zoxide

Zoxide replaces `cd` with a frecency-ranked database of directories you've visited. After visiting a directory once, you can jump back to it from anywhere by typing a fragment of its path. "Frecency" = frequency × recency: a dir you `cd`'d into yesterday and ten times last week beats one you visited once a month ago.

| Command | Behaviour |
|---------|----------|
| `cd nix` | Jump to the highest-ranked directory whose path contains `nix`. From `/tmp` this lands you in `~/.config/nix`. |
| `cd config nix` | Multi-fragment match — every fragment must appear in the path, in order. Picks the highest-ranked match. |
| `cdi config` | Interactive picker (fzf-style) listing all matches by score; arrow-keys + Enter to confirm. |
| `cd ~/Pictures` | Plain absolute/relative paths still work — they bypass the database. |
| `cd -` | Go back to the previous directory (built-in nushell behaviour, unchanged). |
| `cd` (no args) | Home directory. |

The database lives at `~/.local/share/zoxide/db.zo`. It's populated automatically as you navigate — you don't have to bookmark anything. Type `zoxide query --list` to see your current ranking.

#### History: atuin

Atuin replaces shell history with a SQLite database that records each command's exit code, duration, working directory, and host. `Ctrl+r` opens a fuzzy search TUI:

- Type to filter by command text. Configured for `search_mode = "fuzzy"`.
- `Tab` cycles scope: **all hosts** ↔ **this host** ↔ **this session** ↔ **this directory**. The default is "this host".
- `Ctrl+r` again toggles between most-recent and most-frequent ordering.
- `Enter` runs the selected command; `Tab+Enter` puts it on the command line without executing.

#### File / text tools (aliased)

| Alias | Replaces with | What you gain |
|-------|---------------|---------------|
| `vi` / `vim` / `nano` | `hx` | Helix as the system editor everywhere — even when something else (`crontab -e`, `git rebase`) launches `$EDITOR`. |
| `cat` | `bat` | Syntax highlighting, line numbers, automatic paging via `less -FR` for files taller than the terminal. Plain `cat`-like for piped output. |
| `grep` | `rg` (ripgrep) | ~10× faster, recursive by default, respects `.gitignore` automatically, smart-case matching (lowercase pattern → case-insensitive; mixed → case-sensitive). |
| `du` | `dust` | Shows directory sizes as a nested bar chart sorted largest-first. Run in `~/.config/nix` to see what's using space. |
| `ps` | `procs` | Process listing in coloured columns, with `--tree` for parent/child view, `--watch` for live updates, and process search by name as the last argument. |
| `sed` | `sd` | Replaces `sed`'s arcane syntax for the common case of find-and-replace. `sd 'foo' 'bar' file.txt` instead of `sed -i 's/foo/bar/g' file.txt`. |
| `ls` | `eza -1` | Single-column output by default. The bare `eza` invocation also shows git status icons next to each tracked file/dir. |
| `tree` | `eza --tree --git-ignore` | Tree view that skips `.gitignore`d junk (so `target/` and `node_modules/` don't drown the output). |

The aliases live in `modules/shell/aliases.nix` and are exported via `_module.args.shellAliases` so any future shell module can pick them up.

#### Other always-on integrations

- **direnv** + **nix-direnv** — `cd` into a project with an `.envrc` and the dev shell auto-activates (after one-time `direnv allow`). Project-pinned tools (e.g. the rust template's `bacon` + nightly toolchain) appear in `PATH` automatically and disappear when you leave.
- **bat** — used as a pager (`less -FR`) so coloured output works downstream.
- **eza** — git-aware listing with icons; `eza --git --git-ignore --long` is a common power invocation.
- **glow** — render markdown in the terminal: `glow README.md`.
- **tealdeer** — `tldr <cmd>` for community-curated cheat sheets, auto-updates daily.
- **jq** — JSON pipeline tool. Pairs naturally with nushell's `to json` / `from json`.
- **wl-clipboard** — `wl-copy` / `wl-paste` (Wayland clipboard CLIs). `wl-copy < file.txt` to load file contents into the clipboard.

### Scaffolds

Inside any directory:

- `init-rust` — drops the rust template, `git init`, stages, `direnv allow`.
- `init-python` — same, python template.
- `init-go` — same, go template.

### Custom scripts

- `blur-wallpaper <input> [output] [sigma]` — gaussian-blur an image (default sigma 20). Ad-hoc tool: the blurred companion niri's `swaybg` shows in the backdrop layer is derived automatically at build time (`dotfiles.theme.wallpaperBlurred`).

---

## Templates

`nix flake init -t ~/.config/nix#<lang>` drops a `flake.nix`, `flake.lock`, and `.envrc` into the current directory. After `direnv allow`, the dev shell auto-activates on `cd`.

| Template | Provides |
|----------|----------|
| `rust` | Rust 1.90.0 (`rust-src`, `rust-analyzer`, `clippy`, `rustfmt`) + `mold` + `clang`. Dev tools: `bacon`, `cargo-nextest`, `cargo-llvm-cov`, `cargo-udeps`, `cargo-machete`, `cargo-flamegraph`. |
| `python` | Python 3.13, `uv`, `ruff`, `basedpyright`. |
| `go` | `go`, `gopls`, `delve`, `golangci-lint`, `gotools`. |
| `typst` | `typst`, `tinymist`, `typstyle`. |

The nushell scaffolds (`init-rust`, `init-python`, `init-go`) wrap `nix flake init -t`, run `git init` if needed, stage the new files, and `direnv allow` in one go.

---

## Wallpapers

Wallpapers live in `wallpapers/` at the repo root. `dotfiles.theme.wallpaper` (`modules/theming/wallpaper.nix`) is the single source of truth: `awww` displays it on the focused workspace, stylix extracts accent colours from it, and hyprlock uses it as the lock-screen background.

The **blurred** companion that `swaybg` shows in the niri backdrop layer (visible during the overview / between workspaces / behind transparent windows) is not a checked-in file: `dotfiles.theme.wallpaperBlurred` defaults to a derivation that gaussian-blurs the wallpaper (ImageMagick, sigma 20) at build time, so it can never drift out of sync. Set the option to a file to supply a hand-made blur instead.

Because the wallpaper is referenced as a flake-source path, it must be `git add`'d before a rebuild will see it (untracked files are invisible to flakes).

### blur-wallpaper

The `blur-wallpaper` binary (in `$PATH` on every host once HM is activated) applies the same ImageMagick gaussian blur by hand — useful for previewing a sigma or producing a one-off:

```nu
blur-wallpaper <input> [output] [sigma]
#   input:  source image
#   output: defaults to <input-stem>-blur.<input-ext> next to <input>
#   sigma:  blur strength (default 20; higher = blurrier)
```

Sigma rule of thumb: `10` barely-blurred, `20` is the niri-backdrop default (still recognisable as the original), `60+` heavy frosted glass, `120+` almost a solid colour blob. Any format ImageMagick supports (`.png`, `.jpg`, `.webp`, `.heic`, …) works as both input and output.

### Swapping the active wallpaper

```nu
# 1. Drop the new image in
cp ~/Downloads/sunset.jpg wallpapers/sunset.jpg

# 2. Stage it — flakes only see git-tracked files
git add wallpapers/sunset.jpg

# 3. Point dotfiles.theme.wallpaper at it: edit the default in
#    modules/theming/wallpaper.nix (or set the option in a host overlay).
#    The blurred backdrop, stylix colours and hyprlock background all follow.

# 4. Apply
home-manager switch --flake ".#<host>"

# 5. Replace the running daemons (or just log out / Mod+Shift+E and back in)
awww img wallpapers/sunset.jpg
killall swaybg
swaybg -m fill -i "$(grep -oP '(?<=-i" ")/nix/store/\S+(?=")' ~/.config/niri/config.kdl)" &
```

---

## Adding things

### A new host

1. Decide whether it's a NixOS host or standalone HM.
2. Create `hosts/<name>/home.nix` (the HM overlay). Set per-host bits: `home.sessionPath`, host-specific `home.packages`, `programs.niri.settings.outputs`, any `lib.mkForce` overrides.
3. (NixOS only) Create `hosts/<name>/configuration.nix` and `hardware-configuration.nix`, then add `nixosConfigurations.<name>` to `flake.nix`.
4. Add `homeConfigurations.<name> = mkHome "<name>";` to `flake.nix`.
5. Apply: `home-manager switch --flake .#<name>`. On NixOS also `sudo nixos-rebuild switch --flake .#<name>`.

If a module doesn't fit on the new host (e.g. niri-tied stuff on a host running a different DE), set its toggle off in the overlay: `dotfiles.<domain>.<name>.enable = false;`.

### A new module

1. Pick a domain folder under `modules/`. Create `<domain>/<name>.nix`.
2. Wrap the body in the `dotfiles.<domain>.<name>.enable` toggle pattern (see "Modules" above).
3. Add the new file to that domain's `default.nix` `imports = [ ... ]`.
4. Take `colors`, `monoFont`, etc. via function args (they come from `theme.nix` via `_module.args`).
5. Run `nix flake check`. The pre-commit step runs `nixfmt-rfc-style`, `deadnix`, `statix`, `typos`.
6. `home-manager switch --flake .#<host> -n` to dry-run, then drop `-n`.

### A new GUI app on Arch

If the package needs OpenGL (browsers, electron apps, games), add it to the `wrapGL`-mapped list in `hosts/desktop-arch/home.nix` rather than shared `home.packages`. The wrapper rewrites every executable in the package's `bin/` to invoke `nixGLIntel` first.

---

## Updating

```nu
nix flake update                                                # bump all inputs
nix flake update nixpkgs helix niri                             # bump specific inputs
sudo nixos-rebuild switch --flake ~/.config/nix#laptop-nix  # apply system (NixOS only)
home-manager switch --flake ".#desktop-arch"                            # apply user
nh clean all                                                    # gc, respecting nh.nix retention
```

---

## Troubleshooting

**`Command 'welcome' not found` in nushell startup.** The home-manager-symlinked `welcome.nu` resolves to a hashed nix-store name, so `use ~/.config/nushell/welcome.nu` registers a module under that hash. Fixed by `source`ing the file instead of `use`ing it (see `modules/shell/nushell.nix`).

**`ignoring untrusted substituter 'https://niri.cachix.org'`.** Substituters declared in `flake.nix#nixConfig` only apply if the user is trusted. Either run `sudo nixos-rebuild switch` to pick up the system-wide caches in `hosts/laptop-nix/configuration.nix`, or add your user to `nix.settings.trusted-users`.

**`Existing file '...' would be clobbered`.** Pass `-b backup` to home-manager. The conflicting file becomes `<file>.backup`.

**GUI app launches but draws garbage / segfaults on Arch.** It probably skipped the nixGL wrapper. Check it's in the `wrapGL`-mapped list in `hosts/desktop-arch/home.nix` and not in shared `home.packages`. Apps launched via a `.desktop` entry may also bypass the wrapper if the `.desktop`'s `Exec=` resolves the original (unwrapped) binary — point the `.desktop` `Exec=` at the wrapped binary in your nix profile instead.

**`nh home switch` operates on a /nix/store path, not my live edits.** `programs.nh.flake = inputs.self.outPath` in `modules/dev/nh.nix` gives `nh` a store path by default. Pass an explicit path: `nh home switch ~/.config/nix`.

**niri rejects an option I added — `programs.niri.settings.<X> does not exist`.** The niri-flake HM module's typed schema is pinned to a niri version that may lag the upstream KDL grammar (e.g. top-level `blur`, `window-rule { background-effect.blur }`, per-output `layout`). Either bump `inputs.niri`, or escape into the raw KDL via `programs.niri.config = lib.mkForce "<kdl text>"` for the unsupported bits.
