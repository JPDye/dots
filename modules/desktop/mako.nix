{
  config,
  lib,
  colors,
  ...
}:

let
  cfg = config.dotfiles.desktop.mako;
in
{
  options.dotfiles.desktop.mako.enable = lib.mkEnableOption "mako notification daemon" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    services.mako = {
      enable = true;

      settings = {
        border-color = "#${colors.urgent}CC";
        # Translucent (eb ≈ 92%, matching the launcher and floats) so niri's
        # notifications layer-rule blur (window-rules.nix) frosts through it.
        background-color = "#${colors.bg0}eb";
        text-color = "#${colors.fg2}";
        default-timeout = 4000;
      };
    };
  };
}
