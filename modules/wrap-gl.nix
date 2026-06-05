{ lib, ... }:

{
  options.dotfiles.wrapGL = lib.mkOption {
    type = lib.types.functionTo lib.types.package;
    default = pkg: pkg;
    description = ''
      Transform applied to GPU/OpenGL-using packages. Identity on hosts where
      the OS supplies driver libs in the right places (NixOS); on Arch and
      similar this is overridden to wrap each binary with nixGL.
    '';
  };
}
