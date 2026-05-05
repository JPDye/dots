{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.dev.nh;
in
{
  options.dotfiles.dev.nh.enable = lib.mkEnableOption "nh nix helper + nix-output-monitor" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      flake = inputs.self.outPath;
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 5";
      };
    };

    home.packages = [ pkgs.nix-output-monitor ];
  };
}
