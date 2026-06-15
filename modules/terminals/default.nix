{
  config,
  lib,
  pkgs,
  colors,
  ...
}:

let
  # One switch for the terminal the desktop uses. Flipping `primary` swaps the
  # installed program (alacritty.nix / ghostty.nix), the stylix target
  # (theming/stylix.nix), and everything that spawns a terminal (Mod+Return,
  # walker, the work-layout) — those read the derived `terminal` arg below
  # rather than hardcoding a name.
  byTerminal = {
    alacritty = {
      command = "alacritty";
      package = pkgs.alacritty;
      # On Wayland alacritty's `--class <general>` sets app_id, so the
      # work-layout windows come up as `${appIdPrefix}.thin` / `.wide`.
      appIdPrefix = "alacritty";
    };
    ghostty = {
      command = "ghostty";
      package = pkgs.ghostty;
      # ghostty is GTK: app-ids must contain a dot, hence the reverse-DNS form.
      appIdPrefix = "com.mitchellh.ghostty";
    };
  };

  # Canonical 16-slot ANSI palette, mapped to theme colours once here so the
  # terminal modules render from the same source instead of hand-maintaining
  # the remap (yellow->orange, cyan->blue, magenta->pink) twice. Standard ANSI
  # order 0-15 (0-7 normal, 8-15 bright); bare hex, no leading '#'.
  ansiPalette = [
    colors.bg0 # 0  black
    colors.red # 1  red
    colors.green # 2  green
    colors.orange # 3  yellow  -> orange
    colors.blue # 4  blue
    colors.pink # 5  magenta -> pink
    colors.blue # 6  cyan    -> blue
    colors.fg2 # 7  white
    colors.bg3 # 8  bright black
    colors.red # 9  bright red
    colors.green # 10 bright green
    colors.orange # 11 bright yellow  -> orange
    colors.blue # 12 bright blue
    colors.pink # 13 bright magenta -> pink
    colors.blue # 14 bright cyan    -> blue
    colors.fg0 # 15 bright white
  ];
in
{
  imports = [
    ./alacritty.nix
    ./ghostty.nix
    ./zellij.nix
  ];

  options.dotfiles.terminals.primary = lib.mkOption {
    type = lib.types.enum [
      "alacritty"
      "ghostty"
    ];
    default = "alacritty";
    description = ''
      Which terminal is installed, themed, and launched by Mod+Return, walker,
      and the work-layout. Flip to "ghostty" to switch back.
    '';
  };

  # Derived terminal facts the desktop modules consume so the choice lives in
  # one place.
  config._module.args = {
    terminal = byTerminal.${config.dotfiles.terminals.primary};
    terminalPalette = ansiPalette;
  };
}
