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
          # fuzzel appends the program to this for Terminal=true desktop
          # entries; ghostty needs -e or it treats the program as a config arg.
          terminal = "ghostty -e";
          lines = 5;

          dpi-aware = "yes";
          font = lib.mkForce "${monoFont}:size=11";

          horizontal-pad = 16;
          vertical-pad = 16;
          inner-pad = 8;
        };

        colors = {
          # Translucent so niri's launcher layer-rule blur (window-rules.nix)
          # shows through; eb ≈ 92%, the same translucency the floating
          # windows get from their opacity rule.
          background = lib.mkForce "${colors.bg0}eb";

          border = lib.mkForce "${colors.border}ff";

          input = lib.mkForce "${colors.border}ff";
          text = lib.mkForce "${colors.fg2}ff";

          prompt = lib.mkForce "${colors.accent}ff";
          match = lib.mkForce "${colors.accent}ff";

          # Same alpha as the background so the frost continues through
          # the highlight instead of an opaque bar sitting on it.
          selection = lib.mkForce "${colors.bg1}eb";
          selection-text = lib.mkForce "${colors.fg1}ff";
          selection-match = lib.mkForce "${colors.accent}ff";
        };

        border = {
          width = 1;
          radius = lib.mkForce border-style.radius-int;
        };
      };
    };
  };
}
