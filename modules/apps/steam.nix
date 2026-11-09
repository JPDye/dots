{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.apps.steam;
in
{
  options.dotfiles.apps.steam.enable = lib.mkEnableOption "Steam" // {
    default = true;
  };

  # Steam is the only 32-bit GL program in the flake. On a nixGL host it
  # needs nixGL's 32-bit half (enable32bits in flake.nix).
  config = lib.mkIf cfg.enable {
    home.packages = [ (config.dotfiles.wrapGL pkgs.steam) ];
  };
}
