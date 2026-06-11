{ config, lib, ... }:

let
  cfg = config.dotfiles.shell.yazi;
in
{
  options.dotfiles.shell.yazi.enable = lib.mkEnableOption "yazi terminal file manager" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      # `y` opens yazi and cd's the shell to wherever you quit.
      enableNushellIntegration = true;
      # Adopt the new upstream default explicitly; with stateVersion < 26.05
      # home-manager would otherwise keep the legacy `yy` and warn.
      shellWrapperName = "y";
    };
  };
}
