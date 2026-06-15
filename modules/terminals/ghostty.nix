{
  config,
  lib,
  terminalPalette,
  ...
}:

let
  cfg = config.dotfiles.terminals;
in
{
  config = lib.mkIf (cfg.primary == "ghostty") {
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

        # 16-slot ANSI palette from terminals/default.nix (shared with alacritty).
        palette = lib.mkForce (lib.imap0 (i: c: "${toString i}=${c}") terminalPalette);
      };
    };
  };
}
