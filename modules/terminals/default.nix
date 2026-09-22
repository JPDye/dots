{
  ansi,
  config,
  lib,
  pkgs,
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

  # The active scheme's 16-slot ANSI table (palettes/<scheme>.nix). It lives
  # there rather than here so each scheme can ship its own terminal colours:
  # the kintsugi scheme uses its upstream theme's terminal.ansi* values,
  # which deliberately differ from the hues its UI is styled with.
  ansiPalette = ansi;

  # Terminfo search path. Absolute paths only: nushell takes this value as a
  # plain string literal, so `$HOME` would never expand. A directory that
  # does not exist is skipped, so one list covers both NixOS and Arch.
  terminfoDirs = lib.concatStringsSep ":" [
    "${config.home.homeDirectory}/.nix-profile/share/terminfo"
    "/etc/profiles/per-user/${config.home.username}/share/terminfo"
    "/run/current-system/sw/share/terminfo"
    "/usr/share/terminfo"
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
    default = "ghostty";
    description = ''
      Which terminal is installed, themed, and launched by Mod+Return, walker,
      and the work-layout. Flip to "alacritty" to switch back. ghostty is the
      default because alacritty renders no ligatures at all, by design.
    '';
  };

  config = {
    # Derived terminal facts the desktop modules consume so the choice lives
    # in one place.
    _module.args = {
      terminal = byTerminal.${config.dotfiles.terminals.primary};
      terminalPalette = ansiPalette;
    };

    # ghostty ships its own `xterm-ghostty` terminfo entry, and it installs
    # into the nix profile. A program that asks ncurses finds it. A program
    # that does its own terminfo lookup does not: Rust's `term` crate (which
    # rustfmt uses to colour a `--check` diff) searches only $TERMINFO,
    # ~/.terminfo, $TERMINFO_DIRS and /usr/share/terminfo, and neither Arch
    # nor NixOS puts xterm-ghostty in the last of those. The lookup fails,
    # the crate reports no colour support, and the tool prints plain text.
    # Naming the profile in TERMINFO_DIRS fixes every such tool at once.
    home.sessionVariables.TERMINFO_DIRS = terminfoDirs;

    # hm-session-vars.sh is POSIX, and nushell never sources it (see
    # dev/nh.nix), so nushell needs its own copy of the variable.
    programs.nushell.environmentVariables.TERMINFO_DIRS = terminfoDirs;
  };
}
