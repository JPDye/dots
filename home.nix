{
  config,
  hostname,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ./modules/wrap-gl.nix
    ./modules/theming
    ./modules/desktop
    ./modules/terminals
    ./modules/shell
    ./modules/dev
    ./modules/apps
    ./modules/scripts

    inputs.spicetify-nix.homeManagerModules.default
    inputs.textfox.homeManagerModules.textfox
    inputs.nix-index-database.homeModules.nix-index

    ./hosts/${hostname}/home.nix
  ];

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
        );
    };

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = false;
    };
  };
}
