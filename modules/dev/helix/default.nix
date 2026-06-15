{ lib, ... }:

{
  imports = [
    ./themes.nix
    ./editor.nix
    ./languages.nix
  ];

  options.dotfiles.dev.helix.enable = lib.mkEnableOption "helix editor" // {
    default = true;
  };
}
