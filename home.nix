{ config, pkgs, inputs, system, ... }:

{
  home = {
    username = "jd";
    homeDirectory = "/home/jd";
    stateVersion = "23.11";

    sessionPath = [
      "${config.home.homeDirectory}/.apps"
      "/home/linuxbrew/.linuxbrew/bin"
      "${config.home.homeDirectory}/eww/target/release"
    ];

    sessionVariables = {
      RUSTC_WRAPPER = "sccache";
      CARGO_INCREMENTAL = "0";
      SCCACHE_DIR = "${config.home.homeDirectory}/.cache/sccache";
      SCCACHE_CACHE_SIZE = "20G";
      SCCACHE_IDLE_TIMEOUT = "0";
    };

    packages = with pkgs; [
      # niri plumbing
      xwayland-satellite-stable
      swaybg

      # browsers + comms + media
      chromium
      ffmpeg
      foliate
      wireshark-qt

      # games / 3d
      steam
      orca-slicer

      # vpn / net
      wireguard-tools
      protonvpn-gui

      # audio / display
      pavucontrol
      brightnessctl

      # rust build cache
      sccache

      # general cli not covered by other modules
      bottom
      hyperfine
      unzip
      tree

      inputs.claude-code.packages.${system}.default
    ];
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
