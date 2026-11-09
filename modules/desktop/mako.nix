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
        # Solid dark. This was translucent so niri's blur could frost
        # through it. The compositor draws no blur at all now, so an opaque
        # background avoids showing raw windows behind it.
        background-color = "#${colors.bg0}";
        text-color = "#${colors.fg2}";
        default-timeout = 4000;

        # A critical notification (a low battery, for example) stays for
        # 10 s, not 4. ignore-timeout makes mako apply that even when the
        # sender asks for a shorter expiry.
        "urgency=critical" = {
          default-timeout = 10000;
          ignore-timeout = 1;
        };
      };
    };
  };
}
