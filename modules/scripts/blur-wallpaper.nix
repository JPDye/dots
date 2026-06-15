{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.scripts.blur-wallpaper;
in
{
  options.dotfiles.scripts.blur-wallpaper.enable =
    lib.mkEnableOption "blur-wallpaper script (gaussian-blur an image for use as a background)"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "blur-wallpaper";
        runtimeInputs = [ pkgs.imagemagick ];
        text = builtins.readFile ./blur-wallpaper.sh;
      })
    ];
  };
}
