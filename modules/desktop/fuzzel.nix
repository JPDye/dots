{
  config,
  lib,
  colors,
  monoFont,
  border-style,
  ...
}:

let
  cfg = config.dotfiles.desktop.fuzzel;
in
{
  options.dotfiles.desktop.fuzzel.enable = lib.mkEnableOption "fuzzel app launcher" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.fuzzel = {
      enable = true;

      settings = {
        main = {
          icons-enabled = false;
          terminal = "ghostty";
          lines = 5;

          dpi-aware = "yes";
          font = lib.mkForce "${monoFont}:size=11";

          horizontal-pad = 16;
          vertical-pad = 16;
        };

        colors = {
          border = lib.mkForce "${colors.red}ff";

          input = lib.mkForce "${colors.red}ff";
          text = lib.mkForce "${colors.fg2}ff";

          prompt = lib.mkForce "${colors.orange}ff";
          match = lib.mkForce "${colors.orange}ff";

          selection = lib.mkForce "${colors.bg1}ff";
          selection-text = lib.mkForce "${colors.fg1}ff";
          selection-match = lib.mkForce "${colors.orange}ff";
        };

        border = {
          width = 1;
          radius = lib.mkForce border-style.radius-int;
        };
      };
    };
  };
}
