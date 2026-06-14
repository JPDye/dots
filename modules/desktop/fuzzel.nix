{
  config,
  lib,
  colors,
  monoFont,
  border-style,
  terminal,
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
          # entries; the terminal needs -e or it treats the program as a
          # config arg (true for both ghostty and alacritty).
          terminal = "${terminal.command} -e";
          lines = 5;

          dpi-aware = "yes";
          # size 8 matches the clipboard picker (Mod+V, binds.nix) so every
          # fuzzel surface shares one dense look.
          font = lib.mkForce "${monoFont}:size=8";

          # Nerd Font chevron (nf-fa-chevron-right, U+F054). Drafting Mono has
          # no such glyph, so it renders through the Symbols Nerd Font Mono
          # fontconfig fallback, in colors.prompt (the accent). fromJSON
          # decodes the \uf054 escape together with the literal quotes, so the
          # value serialises as `prompt="<chevron> "` and fuzzel keeps the
          # trailing space (it trims unquoted trailing whitespace). The
          # clipboard picker inherits this; other dmenu helpers set --prompt.
          prompt = builtins.fromJSON ''"\"\uf054 \""'';

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
