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
    # Cursor shader, vendored from sahaj-b/ghostty-cursor-shaders (MIT, the
    # licence sits beside it in shaders/). The rectangular boom pulses a box
    # outward from the cursor on each move, in place of the warp trail this
    # used to draw.
    xdg.configFile."ghostty/shaders/rectangle_boom_cursor.glsl".source =
      ../../shaders/rectangle_boom_cursor.glsl;

    programs.ghostty = {
      enable = true;

      settings = {
        command = "zellij";
        shell-integration-features = "cursor,sudo,title";

        cursor-style = "bar";
        cursor-style-blink = true;
        mouse-hide-while-typing = false;

        custom-shader = "${config.xdg.configHome}/ghostty/shaders/rectangle_boom_cursor.glsl";
        custom-shader-animation = "always";

        confirm-close-surface = false;

        # 16-slot ANSI palette from terminals/default.nix (shared with alacritty).
        palette = lib.mkForce (lib.imap0 (i: c: "${toString i}=${c}") terminalPalette);
      };
    };
  };
}
