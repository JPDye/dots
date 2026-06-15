{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.dev.cargoSweep;

  sweep = "${pkgs.cargo-sweep}/bin/cargo-sweep";

  # Home-relative subdirs → absolute paths for the unit.
  roots = lib.escapeShellArgs (map (r: "${config.home.homeDirectory}/${r}") cfg.roots);

  # --hidden makes the recursive walk descend into dot-dirs: Claude Code drops
  # agent worktrees under `.claude/worktrees/<id>/`, each carrying a full
  # multi-GB `target/` the default (dot-dir-skipping) walk would never see.
  timePass = "${sweep} sweep --recursive --hidden --time ${toString cfg.olderThanDays} ${roots}";
  sizePass = "${sweep} sweep --recursive --hidden --maxsize ${toString cfg.maxSize} ${roots}";
in
{
  options.dotfiles.dev.cargoSweep = {
    enable = lib.mkEnableOption "periodic sweep of stale Rust build artifacts" // {
      default = true;
    };

    roots = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "Code"
        "Projects"
      ];
      description = "Directories, relative to $HOME, walked recursively for cargo `target/` dirs.";
    };

    olderThanDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 7;
      description = ''
        Prune build artifacts not touched in this many days; anything newer is
        kept, so an actively-built project retains its working set.
      '';
    };

    maxSize = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "40GB";
      description = ''
        Optional hard backstop run after the time-based pass: trim each
        `target/` to this size by deleting its oldest artifacts. Off by default
        because it also evicts *recent* artifacts, forcing rebuilds — only worth
        enabling for a project that balloons within the time window. Unit
        defaults to MB (e.g. "500", "40GB").
      '';
    };

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = "systemd `OnCalendar` expression controlling how often the sweep runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.cargo-sweep ];

    systemd.user.services.cargo-sweep = {
      Unit.Description = "Prune stale Rust build artifacts (cargo-sweep)";
      Service = {
        Type = "oneshot";
        # cargo-sweep shells out to `cargo metadata` to locate each target dir,
        # so cargo MUST be on PATH — without it the recursive walk silently
        # cleans nothing. A bare stable cargo suffices for almost all manifests.
        # Caveat: a project whose Cargo.toml needs a NEWER cargo than this one —
        # nightly-only manifest features (`cargo-features = [...]`) or an edition
        # this cargo doesn't know — makes `cargo metadata` fail, and cargo-sweep
        # then SILENTLY SKIPS that project (its target/ is never pruned). If a
        # big project stops being swept, that's the cause; point this at a newer
        # cargo (see modules/dev/cargo-sweep.nix maintenance note / plan 016).
        Environment = [ "PATH=${lib.makeBinPath [ pkgs.cargo ]}" ];
        # Background chore: yield to interactive work.
        Nice = 19;
        IOSchedulingClass = "idle";
        ExecStart = [ timePass ] ++ lib.optional (cfg.maxSize != null) sizePass;
      };
    };

    systemd.user.timers.cargo-sweep = {
      Unit.Description = "Schedule for the Rust build-artifact sweep";
      Timer = {
        OnCalendar = cfg.frequency;
        Persistent = true; # catch up after the machine was off at trigger time
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
