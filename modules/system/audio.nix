{ config, lib, ... }:
let
  cfg = config.dotfiles.system.audio;
in
{
  options.dotfiles.system.audio.enable = lib.mkEnableOption "system audio (pipewire + rtkit)" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
    };
  };
}
