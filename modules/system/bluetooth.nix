{ config, lib, ... }:
let
  cfg = config.dotfiles.system.bluetooth;
in
{
  options.dotfiles.system.bluetooth.enable =
    lib.mkEnableOption "system bluetooth (bluez + blueman)"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      # Experimental enables battery reporting for headphones.
      settings.General.Experimental = true;
    };

    services.blueman.enable = true;
  };
}
