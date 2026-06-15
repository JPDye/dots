# CLAUDE.md

Agent-facing contract for this flake. The full tour is in `README.md`; this file
is the short list of conventions, invariants, and gotchas. Keep it thin — add to
it only when something here would have prevented a mistake.

## What this is

A unified Nix flake driving two hosts from one module set:

- **`laptop-nix`** — NixOS. `hosts/laptop-nix/configuration.nix` (system) +
  home-manager run *as a NixOS module*. Built by `mkNixos` in `flake.nix`.
- **`desktop-arch`** — standalone home-manager on Arch Linux. Built by `mkHome`.

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

**Exceptions** (no `enable` toggle — they only publish `_module.args` for
siblings): `modules/theming/theme.nix` and `modules/shell/aliases.nix`.

**System modules** (`modules/system/*.nix`) are NixOS-scoped (imported only by
`hosts/laptop-nix/configuration.nix`), so their toggles live under
`dotfiles.system.<name>` in the NixOS option tree. The *feature* ones — `audio`,
`bluetooth`, `containers`, `fonts`, `greeter`, `plymouth`, `power`, `desktop` —
carry the usual `enable` toggle (default `true`; flip it in a host's
`configuration.nix`). The *structural* ones — `boot`, `nix`, `users`, `locale`,
`networking`, `programs` — are intentionally always-on with **no** toggle (a
host that disabled them wouldn't boot / would have no user / no network).

## Where things live (don't guess)

- **GUI / GPU packages → shared `home.nix`**, inside the
  `map config.dotfiles.wrapGL (…)` list. `wrapGL` is identity on NixOS and
  nixGL-wrapping on Arch (`hosts/desktop-arch/home.nix` sets it; helper in
  `modules/wrap-gl.nix`). Do **not** put packages in host overlays — overlays
  carry only per-host divergence (monitor `outputs`, `lib.mkForce` bind
  overrides, the `wrapGL` definition).
- **Plain CLI tools → shared `home.nix`** unwrapped, or the relevant
  `modules/shell/` module.
- **Theme tokens** (`colors`, `monoFont`, `dotfiles.theme.*`, stylix) are
  **home-manager-scoped** — NixOS system modules can't see them. System surfaces
  (`modules/system/fonts.nix`, greeter, console, plymouth) **hardcode** the value
  with a "keep in sync" comment instead of reading the HM arg.

## Invariants that bite

- **caches**: the extra caches live in **three** places — `caches.nix` (source
  of truth), `flake.nix`'s `nixConfig.extra-*` literals (Nix requires literal
  `nixConfig` values, so `flake.nix` can't import `caches.nix`), and
  `.github/workflows/check.yml`'s `extra-conf` block (YAML can't read Nix).
  Editing a cache means editing **all three**;
  `checks.<system>.caches-in-sync` reads the flake and the CI workflow and
  fails `nix flake check` on drift from `caches.nix`.
- **niri schema lag**: `programs.niri.settings.*` uses niri-flake's typed schema,
  which can lag the niri binary. KDL the schema doesn't know yet goes through
  `dotfiles.desktop.niri.extraConfig` (raw KDL — see
  `modules/desktop/niri/default.nix`).
- **flakes only see git-tracked files**: `git add` new wallpapers/fonts/modules
  before a rebuild, or they're invisible.

## Verifying a change

```
nix flake check
```

builds each host's NixOS toplevel + HM activation, runs `caches-in-sync`, and
runs the pre-commit hooks (`nixfmt`, `deadnix`, `statix`, `typos`). The
pre-commit git hook auto-installs on entering the dev shell via direnv
(`.envrc` = `use flake`). Dry-run an apply with
`home-manager switch --flake .#<host> -n`.

The interactive shell here is **Nushell** — commands you hand the user to run
must be valid Nushell (command substitution is `(cmd)`, not `$(cmd)`; env is
`$env.VAR`, not `export`).

## New dependencies

Tools/runtimes go through the flake (a `modules/` entry, a devshell, or a
`templates/<lang>/flake.nix`) and a rebuild — never an imperative installer
(`npm i -g`, `pip install`, `cargo install`, `apt`, …).
