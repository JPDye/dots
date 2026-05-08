{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.apps.termius;
in
{
  options.dotfiles.apps.termius.enable = lib.mkEnableOption "termius ssh client" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.termius ];
  };
}
