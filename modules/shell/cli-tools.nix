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
