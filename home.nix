{
  config,
  pkgs,
  inputs,
  system,
  ...
}:

{
  home = {
    username = "jd";
    homeDirectory = "/home/jd";
    stateVersion = "23.11";

    sessionPath = [
      "${config.home.homeDirectory}/.apps"
      "${config.home.homeDirectory}/eww/target/release"
    ];

    packages = with pkgs; [
      # niri plumbing
      xwayland-satellite-stable
      swaybg

      # browsers + comms + media
      chromium
      ffmpeg
      foliate
      wireshark
      obsidian
      gpu-screen-recorder-gtk

      # games / 3d
      steam
      orca-slicer

      # vpn / net
      wireguard-tools
      proton-vpn

      # audio / display
      pavucontrol
      brightnessctl

      # color picker (binds Mod+I in niri)
      hyprpicker
      libnotify

      # general cli not covered by other modules
      bottom
      hyperfine
      unzip
      tree

      inputs.claude-code.packages.${system}.default
    ];
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = false;
  };

  imports = [
    # shared args (theme tokens)
    ./modules/theme.nix

    # theming
    ./modules/stylix.nix
    ./modules/fonts.nix

    # command runner
    ./modules/fuzzel.nix

    # sysinfo in terminal
    ./modules/fastfetch.nix

    # prompt
    ./modules/starship.nix

    # shell (nushell + cli tools + integrations + aliases)
    ./modules/shell

    # terminals
    ./modules/alacritty.nix
    ./modules/ghostty.nix

    # terminal multiplexing
    ./modules/zellij.nix

    # editor
    ./modules/helix.nix

    # git
    ./modules/git.nix

    # nix helper + output monitor
    ./modules/nh.nix

    # notifications
    ./modules/mako.nix

    # polkit auth-prompt agent
    ./modules/polkit.nix

    # clipboard history (cliphist + wl-clipboard)
    ./modules/cliphist.nix

    # on-screen-display for volume / brightness / caps-lock
    ./modules/swayosd.nix

    # spotify
    inputs.spicetify-nix.homeManagerModules.default
    ./modules/spicetify.nix

    # firefox
    inputs.textfox.homeManagerModules.textfox
    ./modules/firefox.nix

    # discord
    ./modules/nixcord.nix

    # bar
    ./modules/eww.nix

    # wallpapers
    ./modules/swww.nix

    # compositor user config
    ./modules/niri.nix
  ];
}
