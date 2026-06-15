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

  config = lib.mkIf cfg.enable {
    nixpkgs.config.input-fonts.acceptLicense = true;

    fonts = {
      packages = [
        inputs.myFonts.packages.${system}.ioskeley
        inputs.myFonts.packages.${system}.drafting-mono
        pkgs.nerd-fonts.fira-code
        pkgs.nerd-fonts.droid-sans-mono
        pkgs.nerd-fonts.commit-mono
        pkgs.nerd-fonts.symbols-only
        pkgs.libertinus
        pkgs.input-fonts
        pkgs.lora
        pkgs.font-awesome
      ];

      fontconfig = {
        enable = true;
        # Families come from the palette, which is a plain file so this
        # NixOS-scoped module can read it (theme.nix's monoFont arg lives in
        # the home-manager scope and is not visible here). IoskeleyMono is a
        # Nerd Font (icons built in); the shared fallback chain adds Symbols
        # Nerd Font Mono as an icon backup then Libertinus Math for math
        # glyphs. No serif fallback — all IoskeleyMono.
        defaultFonts =
          let
            palette = import ../theming/palette.nix { inherit lib; };
            fallbacks = [
              "Symbols Nerd Font Mono"
              "Libertinus Math"
            ];
          in
          {
            monospace = [ palette.fonts.mono ] ++ fallbacks;
            serif = [ palette.fonts.serif ] ++ fallbacks;
            sansSerif = [ palette.fonts.serif ] ++ fallbacks;
          };
      };
    };
  };
}
