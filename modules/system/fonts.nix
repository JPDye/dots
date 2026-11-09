{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}:
let
  cfg = config.dotfiles.system.fonts;
in
{
  options.dotfiles.system.fonts.enable =
    lib.mkEnableOption "system font packages + fontconfig defaults"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable (
    let
      palette = import ../theming/palette.nix { inherit lib; };
      fontPackages = import ../theming/font-packages.nix {
        inherit pkgs;
        myFonts = inputs.myFonts.packages.${system};
      };
    in
    {
      nixpkgs.config.input-fonts.acceptLicense = true;

      fonts = {
        # The shared set, plus three faces only this scope installs.
        packages = fontPackages.common ++ [
          pkgs.nerd-fonts.commit-mono
          pkgs.input-fonts
          pkgs.font-awesome
        ];

        fontconfig = {
          enable = true;
          # Families come from the palette, which is a plain file so this
          # NixOS-scoped module can read it (theme.nix's monoFont arg lives
          # in the home-manager scope and is not visible here).
          defaultFonts = {
            monospace = [ palette.fonts.mono ] ++ fontPackages.fallbacks;
            serif = [ palette.fonts.serif ] ++ fontPackages.fallbacks;
            sansSerif = [ palette.fonts.serif ] ++ fontPackages.fallbacks;
          };
        };
      };
    }
  );
}
