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
          # Offline C/POSIX reference: `man 3 printf`, `man 2 write`. Neither
          # nixpkgs nor Arch pulls these in on its own, and section 3 is the C
          # library reference the dev shells assume you have.
          man-pages # Linux man-pages project: sections 2, 3, 4, 5, 7
          man-pages-posix # POSIX pages: sections 0p, 1p, 3p
          ffmpeg
          wireguard-tools
          pavucontrol
          brightnessctl
          libnotify
          bottom
          hyperfine
          unzip
          tree
          socat
          htmlq # CSS selectors over HTML on stdin, like jq for HTML
        ])
        ++ map config.dotfiles.wrapGL (
          with pkgs;
          [
            # GUI / GL-using — wrapped through dotfiles.wrapGL on hosts that need it
            bitwarden-desktop # vault GUI; the firefox addon lives in modules/apps/firefox.nix
            chromium
            dbeaver-bin
            foliate
            wireshark
            obsidian
            gpu-screen-recorder-gtk
            # orca-slicer, the CAD set and Steam each have a module under
            # modules/apps/, so a host can turn them off.
            proton-vpn
            qbittorrent
            roomeqwizard
            slack
            vlc

            # color picker bound to Mod+I in niri
            hyprpicker
          ]
        );
    };

    # The home-manager CLI itself. Needed on the standalone-HM hosts, where
    # nothing else puts `home-manager` in PATH and every rebuild goes through
    # `home-manager switch --flake .#<host>`. Harmless on the NixOS hosts, whose
    # rebuilds go through nixos-rebuild.
    programs.home-manager.enable = true;

    # No `man home-configuration.nix`. Evaluating the manpage costs about 2 s
    # of CPU on every switch, and nixd in Helix already completes these
    # options.
    manual.manpages.enable = false;

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = false;
    };
  };
}
