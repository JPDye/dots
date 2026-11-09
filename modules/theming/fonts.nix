{
  config,
  lib,
  pkgs,
  inputs,
  monoFont,
  serifFont,
  ...
}:

let
  cfg = config.dotfiles.theming.fonts;
in
{
  options.dotfiles.theming.fonts.enable = lib.mkEnableOption "user-level font setup" // {
    default = true;
  };

  config = lib.mkIf cfg.enable (
    let
      fontPackages = import ./font-packages.nix {
        inherit pkgs;
        myFonts = inputs.myFonts.packages.${pkgs.stdenv.hostPlatform.system};
      };
    in
    {
      fonts.fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = [ monoFont ] ++ fontPackages.fallbacks;
          serif = [ serifFont ] ++ fontPackages.fallbacks;
          sansSerif = [ serifFont ] ++ fontPackages.fallbacks;
        };
      };

      # The shared set, plus two faces only this scope installs.
      home.packages = fontPackages.common ++ [
        pkgs.cascadia-code
        pkgs.siji
      ];
    }
  );
}
