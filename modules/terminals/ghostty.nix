{
  config,
  lib,
  colors,
  ...
}:

let
  cfg = config.dotfiles.terminals.ghostty;
in
{
  options.dotfiles.terminals.ghostty.enable = lib.mkEnableOption "ghostty terminal" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."ghostty/shaders/cursor_warp.glsl".source = ../../shaders/cursor_warp.glsl;

    programs.ghostty = {
      enable = true;

      settings = {
        command = "zellij";
        shell-integration-features = "cursor,sudo,title";

        cursor-style = "bar";
        cursor-style-blink = true;
        mouse-hide-while-typing = false;

        custom-shader = "${config.xdg.configHome}/ghostty/shaders/cursor_warp.glsl";
        custom-shader-animation = "always";

        confirm-close-surface = false;

        palette = lib.mkForce [
          "0=${colors.bg0}"
          "1=${colors.red}"
          "2=${colors.green}"
          "3=${colors.orange}"
          "4=${colors.pink}"
          "5=${colors.pink}"
          "6=${colors.pink}"
          "7=${colors.bg3}"
          "8=${colors.bg3}"
          "9=${colors.red}"
          "10=${colors.green}"
          "11=${colors.orange}"
          "12=${colors.pink}"
          "13=${colors.pink}"
          "14=${colors.pink}"
          "15=${colors.fg2}"
        ];
      };
    };
  };
}
