{
  config,
  hostname,
  inputs,
  pkgs,
  ...
}:

let
  # orca-slicer / bambu-studio pinned to nixos-25.11 (see flake.nix input):
  # 26.11's orca 2.4.1 regressed file dialogs, and its bambu-studio is uncached.
  # Both versions here are prebuilt in the binary cache — no local compile.
  pkgs2511 = import inputs.nixpkgs-2511 {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
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
            pkgs2511.orca-slicer # 2.3.2 — 2.4.1 regressed file dialogs on 26.11
            pkgs2511.bambu-studio # cached build — avoids the hour-long compile
            openscad # 3D CAD modeller (GL); 2021.01 stable, cached
            freecad-wayland # qt6 + native Wayland build for niri
            proton-vpn
            qbittorrent
            roomeqwizard
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
