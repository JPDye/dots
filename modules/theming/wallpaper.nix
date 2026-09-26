{
  config,
  lib,
  pkgs,
  ...
}:

let
  palette = import ./palette.nix { inherit lib; };
  cfg = config.dotfiles.theme;
in
{
  options.dotfiles.theme = {
    wallpaper = lib.mkOption {
      type = lib.types.path;
      default = palette.wallpaper;
      description = ''
        The wallpaper image, read from `modules/theming/palette.nix` —
        change it there so the greeter backdrop follows too. Consumed by
        awww (niri/spawn.nix), stylix colour extraction (stylix.nix) and the
        hyprlock background (lock.nix).
      '';
    };

    wallpaperBlurred = lib.mkOption {
      type = lib.types.path;
      # Sigma 15, a medium-heavy backdrop blur. The greeter backdrop and the
      # blur-wallpaper script default use a heavier sigma 20.
      default =
        pkgs.runCommand "wallpaper-blur.png"
          {
            nativeBuildInputs = [ pkgs.imagemagick ];
          }
          ''
            magick ${cfg.wallpaper} -blur 0x15 PNG:$out
          '';
      defaultText = lib.literalMD "`dotfiles.theme.wallpaper` gaussian-blurred at build time (sigma 15)";
      description = ''
        Blurred companion to `wallpaper`, shown by swaybg in the niri
        backdrop layer. Derived from `wallpaper` at build time; set this to
        a file to supply a hand-made blur instead.
      '';
    };
  };
}
