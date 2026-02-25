{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:

{
  imports = [
    ./modules/theming
    ./modules/desktop
    ./modules/terminals
    ./modules/shell
    ./modules/dev
    ./modules/apps
    ./modules/scripts

    inputs.spicetify-nix.homeManagerModules.default
    inputs.textfox.homeManagerModules.textfox

    ./hosts/${hostname}/home.nix
  ];

  options.dotfiles.wrapGL = lib.mkOption {
    type = lib.types.functionTo lib.types.package;
    default = pkg: pkg;
    description = ''
      Transform applied to GPU/OpenGL-using packages. Identity on hosts where
      the OS supplies driver libs in the right places (NixOS); on Arch and
      similar this is overridden to wrap each binary with nixGL.
    '';
  };

  config = {
    home = {
      username = "jd";
      homeDirectory = "/home/jd";
      stateVersion = "23.11";

      sessionPath = [ "${config.home.homeDirectory}/.apps" ];

      packages =
        (with pkgs; [
          # CLI / non-GL — installed unwrapped on every host
          ffmpeg
          wireguard-tools
          pavucontrol
          brightnessctl
          libnotify
          bottom
          hyperfine
          unzip
          tree
        ])
        ++ map config.dotfiles.wrapGL (
          with pkgs;
          [
            # GUI / GL-using — wrapped through dotfiles.wrapGL on hosts that need it
            chromium
            dbeaver-bin
            foliate
            wireshark
            obsidian
            gpu-screen-recorder-gtk
            steam
            orca-slicer
            proton-vpn
            qbittorrent
            slack
            vlc

            # niri plumbing — niri spawns these at startup; both need GL
            xwayland-satellite-stable
            swaybg

            # color picker bound to Mod+I in niri
            hyprpicker
          ]
        )
        ++ [ inputs.claude-code.packages.${system}.default ];
    };

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = false;
    };
  };
}
