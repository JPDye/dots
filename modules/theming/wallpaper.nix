{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.theme;
in
{
  options.dotfiles.theme = {
    wallpaper = lib.mkOption {
      type = lib.types.path;
      # default = ../../wallpapers/socrates.jpg;
      default = ../../wallpapers/istanbul.jpg;
      description = ''
        The wallpaper image — single source of truth, consumed by awww
        (niri/spawn.nix), stylix colour extraction (stylix.nix) and the
        hyprlock background (lock.nix).
      '';
    };

    wallpaperBlurred = lib.mkOption {
      type = lib.types.path;
      # Sigma 20 matches the blur-wallpaper script's default, which produced
      # the previously checked-in *-blur companions.
      default =
        pkgs.runCommand "wallpaper-blur.png"
          {
            nativeBuildInputs = [ pkgs.imagemagick ];
          }
          ''
            magick ${cfg.wallpaper} -blur 0x20 PNG:$out
          '';
      defaultText = lib.literalMD "`dotfiles.theme.wallpaper` gaussian-blurred at build time (sigma 20)";
      description = ''
        Blurred companion to `wallpaper`, shown by swaybg in the niri
        backdrop layer. Derived from `wallpaper` at build time; set this to
        a file to supply a hand-made blur instead.
      '';
    };
  };
}
