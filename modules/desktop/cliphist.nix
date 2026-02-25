{ config, lib, ... }:

let
  cfg = config.dotfiles.desktop.cliphist;
in
{
  options.dotfiles.desktop.cliphist.enable = lib.mkEnableOption "cliphist clipboard history" // {
    default = true;
  };

  # wl-clipboard lives in modules/shell/cli-tools.nix.
  config = lib.mkIf cfg.enable {
    services.cliphist = {
      enable = true;
      systemdTargets = [ "graphical-session.target" ];
    };
  };
}
