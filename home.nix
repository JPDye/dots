{
  config,
  hostname,
  inputs,
  pkgs,
  ...
}:

let
  # Not in nixpkgs — packaged locally from the official AppImage release.
  # Bump with pkgs/zoo-design-studio/update.sh.
  zoo-design-studio = pkgs.callPackage ./pkgs/zoo-design-studio { };
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
            # orca-slicer lives in modules/apps/orca-slicer.nix (pinned 26.05
            # build; per-host loginFix toggle)
            # lycheeslicer lives in modules/apps/lychee-slicer.nix (login
            # URL-handler fix)
            openscad # 3D CAD modeller (GL); 2021.01 stable, cached
            freecad-wayland # qt6 + native Wayland build for niri
            zoo-design-studio # KCL-based CAD (GL) — local pkg, see pkgs/zoo-design-studio
            dune3d # parametric 3D CAD (GL)
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
