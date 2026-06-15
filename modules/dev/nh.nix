{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.dev.nh;
  # Plain filesystem path, not `inputs.self.outPath` — the latter freezes to the
  # store path of the flake at build time, which makes nh ignore working-tree
  # edits. This way each `nh` run re-reads the live source.
  flakePath = "${config.home.homeDirectory}/.config/nix";
in
{
  options.dotfiles.dev.nh.enable = lib.mkEnableOption "nh nix helper + nix-output-monitor" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      flake = flakePath;
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 5";
      };
    };

    # The nh module exports NH_FLAKE through home.sessionVariables, which only
    # reaches hm-session-vars.sh — a POSIX script that nushell never sources. So
    # an interactive nu sees no NH_FLAKE, and a bare `nh home switch` fails with
    # "No installable specified". Set it in nushell's own env as well.
    programs.nushell.environmentVariables.NH_FLAKE = flakePath;

    home.packages = [ pkgs.nix-output-monitor ];
  };
}
