{
  config,
  lib,
  pkgs,
  ...
}:

let
  # One switch for the terminal the desktop uses. Flipping `primary` swaps the
  # installed program (alacritty.nix / ghostty.nix), the stylix target
  # (theming/stylix.nix), and everything that spawns a terminal (Mod+Return,
  # fuzzel, the work-layout) — those read the derived `terminal` arg below
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
      Which terminal is installed, themed, and launched by Mod+Return, fuzzel,
      and the work-layout. Flip to "ghostty" to switch back.
    '';
  };

  # Derived terminal facts the desktop modules consume so the choice lives in
  # one place.
  config._module.args.terminal = byTerminal.${config.dotfiles.terminals.primary};
}
