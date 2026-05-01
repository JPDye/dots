# Multi-host home-manager refactor

Planning notes for converting this flake from single-host (Arch, hostname
`arch`) to multi-host so the same modules can drive a NixOS box without a
fork. Three changes, in dependency order:

1. **Portability** — same flake activates on Arch and NixOS via standalone
   `home-manager switch --flake .#<host>`.
2. **Per-module enable toggles** — every module exposes
   `dotfiles.<name>.enable`, defaulting to `true`. A `hosts/<hostname>.nix`
   layer flips the divergent ones.
3. **Domain-grouped layout** — replace the flat `modules/` with
   `modules/{theming,desktop,terminals,shell,dev,apps}/`.

Username stays `jd` on both hosts. Standalone HM on both. `flake-parts` /
`treefmt-nix` / `nixfmt-rfc-style` are explicitly out of scope.

---

## 1. Flake plumbing

`flake.nix` — add a `mkHome` helper, key `homeConfigurations` by hostname:

```nix
mkHome = hostname: inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules = [
    inputs.stylix.homeModules.stylix
    ./home.nix
    ./hosts/${hostname}.nix
  ];
  extraSpecialArgs = { inherit inputs hostname; };
};
```

```nix
homeConfigurations = {
  arch  = mkHome "arch";
  nixos = mkHome "nixos";   # rename when the NixOS box gets a real name
};
```

Activation on either host: `home-manager switch --flake .#<hostname>`
(or `nh home switch -- --flake .#<hostname>` once the `nh` module is in).

---

## 2. Hardcoded paths to fix

| File | Today | Change |
|------|-------|--------|
| `modules/dev/helix.nix` (post-reorg) | `homeConfigurations.jd.options` in the nixd config | `homeConfigurations.${hostname}.options` (read `hostname` from `extraSpecialArgs`) |
| `home.nix` `sessionPath` | `~/.apps`, `linuxbrew`, `~/eww/target/release` all in shared list | Keep `~/.apps` shared; move `linuxbrew` and `eww` paths into `hosts/arch.nix` |
| `home.nix` `home.packages` | `[ discord xwayland-satellite-stable ]` shared | Keep `discord` shared; move `xwayland-satellite-stable` (niri-tied) into `hosts/arch.nix` |

Username and `homeDirectory` stay in shared `home.nix` (both hosts use `jd`).

---

## 3. Module options pattern

Every domain module wraps its body in `lib.mkIf` against a typed enable
flag, default-on:

```nix
{ config, lib, ... }:
let cfg = config.dotfiles.<name>;
in {
  options.dotfiles.<name>.enable =
    lib.mkEnableOption "<short description>" // { default = true; };

  config = lib.mkIf cfg.enable {
    # existing module body
  };
}
```

Three exceptions stay unwrapped because they only set `_module.args` for
other modules to consume:

- `modules/theming/theme.nix` — provides `colors`, `monoFont`, `border-style`
- `modules/shell/aliases.nix` — provides `shellAliases`

`modules/theming/stylix.nix` references several toggleable modules
(`stylix.targets.firefox.enable`, `…spicetify.enable`, `…ghostty.enable`).
Guard each reference with `lib.mkIf config.dotfiles.<name>.enable` so
disabling, e.g., firefox doesn't break stylix evaluation.

---

## 4. New layout

```
modules/
├── theming/
│   ├── default.nix         imports theme + stylix + fonts
│   ├── theme.nix           color/font/border tokens (no toggle)
│   ├── stylix.nix          (dotfiles.theming.stylix)
│   └── fonts.nix           (dotfiles.theming.fonts)
├── desktop/
│   ├── default.nix
│   ├── fuzzel.nix          (dotfiles.desktop.fuzzel) — also covers tofi
│   └── mako.nix            (dotfiles.desktop.mako)
├── terminals/
│   ├── default.nix
│   ├── alacritty.nix       (dotfiles.terminals.alacritty)
│   ├── ghostty.nix         (dotfiles.terminals.ghostty)
│   └── zellij.nix          (dotfiles.terminals.zellij)
├── shell/
│   ├── default.nix         imports aliases + cli-tools + integrations + nushell + starship + fastfetch
│   ├── aliases.nix         (no toggle — pure args plumbing)
│   ├── cli-tools.nix       (dotfiles.shell.cliTools)
│   ├── integrations.nix    (dotfiles.shell.integrations)
│   ├── nushell.nix         (dotfiles.shell.nushell)
│   ├── starship.nix        (dotfiles.shell.starship)  [moved from modules/starship/]
│   ├── fastfetch.nix       (dotfiles.shell.fastfetch) [moved; called by welcome.nu]
│   └── nushell/
│       ├── welcome.nu
│       └── scaffolds.nu
├── dev/
│   ├── default.nix
│   ├── git.nix             (dotfiles.dev.git)
│   ├── helix.nix           (dotfiles.dev.helix)
│   └── nh.nix              (dotfiles.dev.nh)
└── apps/
    ├── default.nix
    ├── firefox.nix         (dotfiles.apps.firefox)
    └── spicetify.nix       (dotfiles.apps.spicetify)
```

`home.nix` becomes:

```nix
imports = [
  ./modules/theming
  ./modules/desktop
  ./modules/terminals
  ./modules/shell
  ./modules/dev
  ./modules/apps

  inputs.spicetify-nix.homeManagerModules.default
  inputs.textfox.homeManagerModules.default
];
```

The third-party HM modules stay imported in `home.nix`; the wrapper modules
configure them under `lib.mkIf`.

---

## 5. Per-host files

`hosts/arch.nix` — current host, mirrors today's behaviour:

```nix
{ config, pkgs, ... }:
{
  home.sessionPath = [
    "/home/linuxbrew/.linuxbrew/bin"
    "${config.home.homeDirectory}/eww/target/release"
  ];
  home.packages = [ pkgs.xwayland-satellite-stable ];
  # all dotfiles.*.enable left at default (true)
}
```

`hosts/nixos.nix` — empty starter, fill in once the box is up:

```nix
{ ... }:
{
  # NixOS-specific tweaks. Likely candidates for opt-out:
  #   dotfiles.apps.spicetify.enable = false;
  #   dotfiles.terminals.alacritty.enable = false;
}
```

Rename the file to the actual hostname when chosen.

---

## 6. Critical files

| Path | Action |
|------|--------|
| `flake.nix` | Add `mkHome`, host-keyed `homeConfigurations` |
| `home.nix` | Switch to domain-folder imports; move host-specific bits out |
| `hosts/arch.nix` | New; absorbs current host-specific bits |
| `hosts/nixos.nix` | New; empty starter |
| `modules/{theming,desktop,terminals,dev,apps}/default.nix` | New; domain index files |
| `modules/shell/default.nix` | Update to import starship + fastfetch from new location |
| Each `modules/<domain>/<name>.nix` | Wrap body in `lib.mkIf cfg.enable`, declare `options.dotfiles.<name>.enable` |
| `modules/dev/helix.nix` | Replace `homeConfigurations.jd.options` with `homeConfigurations.${hostname}.options` |
| `modules/theming/stylix.nix` | Guard `stylix.targets.<x>.enable` refs with `lib.mkIf config.dotfiles.<x>.enable` |

Files that **move** (use `git mv` so history follows):

- `modules/theme.nix` → `modules/theming/theme.nix`
- `modules/stylix.nix` → `modules/theming/stylix.nix`
- `modules/fonts.nix` → `modules/theming/fonts.nix`
- `modules/fuzzel.nix` → `modules/desktop/fuzzel.nix`
- `modules/mako.nix` → `modules/desktop/mako.nix`
- `modules/alacritty.nix` → `modules/terminals/alacritty.nix`
- `modules/ghostty.nix` → `modules/terminals/ghostty.nix`
- `modules/zellij.nix` → `modules/terminals/zellij.nix`
- `modules/git.nix` → `modules/dev/git.nix`
- `modules/helix.nix` → `modules/dev/helix.nix`
- `modules/nh.nix` → `modules/dev/nh.nix`
- `modules/firefox.nix` → `modules/apps/firefox.nix`
- `modules/spicetify.nix` → `modules/apps/spicetify.nix`
- `modules/fastfetch.nix` → `modules/shell/fastfetch.nix`
- `modules/starship/starship.nix` → `modules/shell/starship.nix` (drop the empty `starship/` dir)

---

## 7. Existing patterns reused

- **`_module.args`** for shared tokens (`colors`, `monoFont`, `border-style`,
  `shellAliases`) — already used at `modules/theme.nix` and
  `modules/shell/aliases.nix`. The toggle wrapper does not affect modules
  that only set `_module.args`.
- **`pre-commit-check`** in `flake.nix` — unchanged; still gates fmt /
  deadnix / statix on the new file layout (no per-path config).

---

## 8. Verification

Arch host first (current must keep working):

1. `nix flake check` — pre-commit (nixpkgs-fmt + deadnix + statix) clean.
2. `nix eval .#homeConfigurations.arch.activationPackage --no-link` — eval-only.
3. `nh home switch -- --flake .#arch -n` — dry run.
4. `nh home switch -- --flake .#arch` — real switch. Then exercise:
   - helix (verify nixd LSP still resolves home-manager options — the
     `${hostname}` swap is the riskiest spot)
   - ghostty + zellij + nushell + starship
   - fuzzel + mako
5. NixOS host: `home-manager switch --flake .#nixos`. Iterate
   `hosts/nixos.nix` to disable modules that don't fit.
6. Toggle smoke test: in `hosts/arch.nix` set
   `dotfiles.apps.firefox.enable = false;`, re-eval, confirm firefox is no
   longer in the closure and stylix doesn't error. Revert.

---

## Out of scope

- `flake-parts`, `treefmt-nix`, `nixfmt-rfc-style` swap.
- NixOS-module activation path (HM-as-NixOS-module). Standalone HM on both.
- SSH commit signing, lazygit, `gh`, `xdg.userDirs` — separate decisions.
