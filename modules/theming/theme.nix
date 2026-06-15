{ config, lib, ... }:

let
  palette = import ./palette.nix { inherit lib; };
  cfg = config.dotfiles.theme;
in
{
  options.dotfiles.theme.variant = lib.mkOption {
    type = lib.types.enum [
      "dark"
      "light"
    ];
    default = palette.variant;
    description = ''
      Active color scheme variant. Change it in
      `modules/theming/palette.nix`, not here: the NixOS-scoped surfaces
      (greeter, fontconfig) import the palette directly and cannot see this
      option, so overriding it per host moves only the home-manager side.

      Modules should consume `colors` (which points at the active palette)
      and may also reference `colorsDark` / `colorsLight` directly when they
      need both available simultaneously.
    '';
  };

  config._module.args = {
    inherit (palette)
      themeLib
      border-style
      shadow-style
      ;

    monoFont = palette.fonts.mono;
    serifFont = palette.fonts.serif;

    colors = if cfg.variant == "light" then palette.light else palette.dark;
    colorsDark = palette.dark;
    colorsLight = palette.light;

    # The active palette as a base16 attrset, for stylix.
    base16Scheme = palette.mkScheme cfg.variant;
  };
}
