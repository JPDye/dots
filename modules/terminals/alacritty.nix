{
  config,
  lib,
  terminalPalette,
  ...
}:

let
  cfg = config.dotfiles.terminals;
  # alacritty's TOML wants a leading '#'; index into the shared palette.
  at = i: "#${builtins.elemAt terminalPalette i}";
in
{
  config = lib.mkIf (cfg.primary == "alacritty") {
    programs.alacritty = {
      enable = true;

      settings = {
        # zellij as the shell, matching ghostty's `command = "zellij"`. The
        # work-layout's `-e zellij …` overrides this for its own panes.
        terminal.shell.program = "zellij";

        cursor.style = {
          shape = "Beam";
          blinking = "On";
        };

        mouse.hide_when_typing = false;

        # 16-slot ANSI palette from terminals/default.nix (shared with ghostty:
        # yellow->orange, cyan->blue, magenta->pink). Overrides the palette
        # stylix sets via its alacritty target; fg/bg/cursor still come from
        # stylix.
        colors.normal = lib.mkForce {
          black = at 0;
          red = at 1;
          green = at 2;
          yellow = at 3;
          blue = at 4;
          magenta = at 5;
          cyan = at 6;
          white = at 7;
        };
        colors.bright = lib.mkForce {
          black = at 8;
          red = at 9;
          green = at 10;
          yellow = at 11;
          blue = at 12;
          magenta = at 13;
          cyan = at 14;
          white = at 15;
        };
      };
    };
  };
}
