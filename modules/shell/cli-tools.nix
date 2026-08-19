{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.shell.cliTools;
in
{
  options.dotfiles.shell.cliTools.enable = lib.mkEnableOption "general-purpose CLI tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ripgrep
      fd
      dust
      procs
      sd
      jq
      tokei
      glow
      tdf
      wl-clipboard
      libqalculate
      # git, bat and delta all default to `less` as their pager. NixOS ships it
      # in the required system path, Arch does not, so `git branch` fails with
      # "cannot run less" on the Arch host. Provide it from the flake instead.
      less
      # Combined traceroute+ping TUI (binary: `trip`). Needs raw sockets, so
      # run `sudo trip <host>`; a capless cap_net_raw wrapper is a NixOS
      # system concern, intentionally not done here (see plan 033).
      trippy
    ];

    programs.tealdeer = {
      enable = true;
      settings = {
        updates.auto_update = true;
      };
    };
  };
}
