{ config, pkgs, ... }:
{
  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/.config/nix";
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
  };

  home.packages = [ pkgs.nix-output-monitor ];
}
