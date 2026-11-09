{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.apps.cad;
in
{
  options.dotfiles.apps.cad.enable = lib.mkEnableOption "CAD modellers and the resin slicer" // {
    default = true;
  };

  # The FDM slicer has its own module (orca-slicer.nix), because it needs a
  # pinned nixpkgs. These need nothing special. FreeCAD is the largest
  # package in the closure (about 4.8 GiB), so a host without the printer
  # can turn the whole set off.
  config = lib.mkIf cfg.enable {
    home.packages = map config.dotfiles.wrapGL (
      with pkgs;
      [
        lycheeslicer # resin (MSLA) slicer — Anycubic Photon
        openscad # 3D CAD modeller (GL); 2021.01 stable, cached
        freecad-wayland # qt6 + native Wayland build for niri
        dune3d # parametric 3D CAD (GL)
      ]
    );
  };
}
