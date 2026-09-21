{ lib, ... }:

let
  palette = import ./palette.nix { inherit lib; };
in
{
  # No options here. The scheme is chosen in `modules/theming/palette.nix`,
  # which the NixOS-scoped surfaces (greeter, fontconfig) import directly and
  # which cannot see a home-manager option.
  config._module.args = {
    inherit (palette)
      themeLib
      border-style
      shadow-style
      colors
      syntax
      base16Scheme
      ;

    monoFont = palette.fonts.mono;
    serifFont = palette.fonts.serif;
  };
}
