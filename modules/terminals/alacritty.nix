{
  config,
  lib,
  colors,
  ...
}:

let
  cfg = config.dotfiles.terminals;

  # `colors.*` are bare hex (theme.nix); alacritty's TOML wants a leading #.
  hex = c: "#${c}";
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

        # Custom ANSI palette mirroring ghostty.nix: yellow->orange,
        # cyan->blue, magenta->pink. Overrides the palette stylix sets via its
        # alacritty target (theming/stylix.nix); fg/bg/cursor still come from
        # stylix.
        colors.normal = lib.mkForce {
          black = hex colors.bg0;
          red = hex colors.red;
          green = hex colors.green;
          yellow = hex colors.orange;
          blue = hex colors.blue;
          magenta = hex colors.pink;
          cyan = hex colors.blue;
          white = hex colors.fg2;
        };
        colors.bright = lib.mkForce {
          black = hex colors.bg3;
          red = hex colors.red;
          green = hex colors.green;
          yellow = hex colors.orange;
          blue = hex colors.blue;
          magenta = hex colors.pink;
          cyan = hex colors.blue;
          white = hex colors.fg0;
        };
      };
    };
  };
}
