# CLAUDE.md

Agent-facing contract for this flake. The full tour is in `README.md`; this file
is the short list of conventions, invariants, and gotchas. Keep it thin — add to
it only when something here would have prevented a mistake.

## What this is

A unified Nix flake driving three hosts from one module set:

- **`laptop-nix`**, **`nix-desktop`** — NixOS. `hosts/<host>/configuration.nix`
  (system) + home-manager run *as a NixOS module*. Built by `mkNixos` in
  `flake.nix` (host lists: `nixosHosts` / `homeHosts` there).
- **`laptop-arch`** — standalone home-manager on Arch Linux. Built by `mkHome`.

`home.nix` is the shared HM base; it imports every domain under `modules/` plus
the active host's `hosts/<host>/home.nix` overlay.

## Module convention

Every file under `modules/<domain>/<name>.nix`:

```nix
{ config, lib, ... }:
let cfg = config.dotfiles.<domain>.<name>;
in {
  options.dotfiles.<domain>.<name>.enable =
    lib.mkEnableOption "<desc>" // { default = true; };
  config = lib.mkIf cfg.enable { /* body */ };
}
```

and is **hand-listed** in that domain's `default.nix` `imports` (no
filesystem auto-discovery). To disable something on a host, set its toggle
`false` in the host overlay.

**No `enable` toggle** in two cases, so do not add one when a new module fits
either:

1. It only publishes `_module.args` or options for siblings to read:
   `modules/theming/theme.nix`, `modules/shell/aliases.nix`,
   `modules/theming/wallpaper.nix`, `modules/terminals/default.nix` (which also
   declares the `dotfiles.terminals.primary` selector).
2. A sibling or parent selector already gates it:
   `modules/terminals/alacritty.nix` and `ghostty.nix` gate on
   `cfg.primary == "..."`, and the `modules/desktop/niri/*.nix` children ride
   the parent module's toggle.

A domain's `default.nix` is a plain `imports` list and needs no toggle either.
Everything else carries its own.

**System modules** (`modules/system/*.nix`) are NixOS-scoped (imported by each
NixOS host's `configuration.nix`), so their toggles live under
`dotfiles.system.<name>` in the NixOS option tree. The nine *feature* ones
(`audio`, `bitdefender`, `bluetooth`, `containers`, `desktop`, `fonts`,
`greeter`, `plymouth`, `power`) carry the usual `enable` toggle, flipped in a
host's `configuration.nix`. Seven of them default `true`. Two default **off**:
`power` (laptop-only, switched on by `profiles/laptop.nix`) and `bitdefender`
(only `hosts/laptop-nix/configuration.nix` enables it). The six *structural*
ones (`boot`, `nix`, `users`, `locale`, `networking`, `programs`) are
intentionally always-on with **no** toggle. A host that disabled them would not
boot, or would have no user, or no network.

## Where things live (don't guess)

- **Form-factor config → `profiles/{laptop,desktop}.nix`.** The middle tier
  between always-shared `modules/` and a host's per-machine divergence: settings
  true of *all laptops* (or *all desktops*) but not universal. Each NixOS host
  imports exactly one profile in its `configuration.nix`. Laptop-only system
  modules (e.g. `power` — TLP/battery) default their toggle **off** and are
  switched on by `profiles/laptop.nix`, so a bare desktop never inherits them.
  Per-machine values (resume_offset, monitor `outputs`, nixos-hardware chassis
  profile) still live in the host, not the profile.
- **GUI / GPU packages → shared `home.nix`**, inside the
  `map config.dotfiles.wrapGL (…)` list. `wrapGL` is identity on NixOS and
  nixGL-wrapping on Arch (`hosts/laptop-arch/home.nix` sets it; helper in
  `modules/wrap-gl.nix`). Do **not** put packages in host overlays — overlays
  carry only per-host divergence (monitor `outputs`, `lib.mkForce` bind
  overrides, the `wrapGL` definition).
- **Plain CLI tools → shared `home.nix`** unwrapped, or the relevant
  `modules/shell/` module.
- **Theme tokens** (`colors`, `monoFont`, `dotfiles.theme.*`, stylix) are
  **home-manager-scoped**, so NixOS system modules cannot see them. They read
  the palette directly instead: `modules/theming/palette.nix` is a plain file
  rather than a module precisely so a NixOS-scoped module can
  `import ../theming/palette.nix { inherit lib; }` (see
  `modules/system/greeter.nix` and `modules/system/fonts.nix`). Import it. Do
  **not** hardcode a copy behind a "keep in sync" comment.

## Invariants that bite

- **caches**: the extra caches live in **four** places — `caches.nix` (source
  of truth), `flake.nix`'s `nixConfig.extra-substituters` (URLs only: Nix
  requires literal `nixConfig` values, and the public keys are deliberately
  absent because that setting is ignored for untrusted users and no user is
  trusted), `.github/workflows/check.yml`'s `extra-conf` block (URLs and keys,
  YAML can't read Nix), and README.md's Arch prerequisite step 3 (URLs and
  keys, pasted into `/etc/nix/nix.conf`). Editing a cache means editing **all
  four**; `checks.<system>.caches-in-sync` reads the flake, the CI workflow
  and the README and fails `nix flake check` on drift from `caches.nix`.
- **niri schema lag**: `programs.niri.settings.*` uses niri-flake's typed schema,
  which can lag the niri binary. KDL the schema doesn't know yet goes through
  `dotfiles.desktop.niri.extraConfig` (raw KDL — see
  `modules/desktop/niri/default.nix`).
- **flakes only see git-tracked files**: `git add` new wallpapers/fonts/modules
  before a rebuild, or they're invisible.
- **walker needs elephant to restart before it sees a new app**: elephant
  (walker's backend, a long-running user service) scans desktop entries at
  startup, and a rebuild replaces the profile symlink under it. The
  `refreshWalker` activation hook in `modules/desktop/walker.nix` now restarts
  both services on every `switch`, so this is automatic. The hook is a no-op
  when no graphical session is live, so a rebuild from a TTY still needs
  `systemctl --user restart elephant.service walker.service` after login.
  A CLI tool never appears in walker either way, because walker lists desktop
  entries and a CLI tool ships none.

## Verifying a change

Three tiers, cheapest first. Run the cheapest one that can catch what you
changed.

1. `pre-commit run --all-files` (seconds). Runs the hooks only: `nixfmt`,
   `deadnix`, `statix`, `shellcheck`, `typos`, `nu-check`. Catches formatting,
   dead code, spelling, and shell / Nushell syntax. It evaluates no Nix.
2. `nix flake check --no-build` (minutes). What CI runs. Catches option and
   eval breakage across every host, plus `caches-in-sync`, `hm-options` and
   the installer host template (all three assert at eval time). It does
   **not** catch build-time failures, such as `niri validate` on the
   generated KDL or the shellcheck inside `writeShellApplication`.
3. `nix flake check` (full). Everything above, and it builds each host's NixOS
   toplevel + HM activation. This is the gate before a `switch`.

The pre-commit git hook auto-installs on entering the dev shell via direnv
(`.envrc` = `use flake`). Dry-run an apply before a `switch`. On a NixOS host:
`nixos-rebuild build --flake .#<host>` (builds the toplevel, activates
nothing, needs no root). On `laptop-arch`, the standalone home-manager host:
`home-manager switch --flake .#<host> -n`. The NixOS hosts have no
`homeConfigurations` entry, so the `-n` form fails there.

The interactive shell here is **Nushell** — commands you hand the user to run
must be valid Nushell (command substitution is `(cmd)`, not `$(cmd)`; env is
`$env.VAR`, not `export`).

## New dependencies

Tools/runtimes go through the flake (a `modules/` entry, a devshell, or a
`templates/<lang>/flake.nix`) and a rebuild — never an imperative installer
(`npm i -g`, `pip install`, `cargo install`, `apt`, …).

One exception exists, and it is not a precedent: the Bitdefender product on
`laptop-nix`. The vendor ships an FHS `.deb` that nixpkgs cannot package, so
`hosts/laptop-nix/bitdefender/bootstrap.sh` installs it once by hand into
`/opt`. `modules/system/bitdefender.nix` still owns the whole declarative half
(units, timers, sudoers rule, `/bin` shims, nix-ld libraries).
