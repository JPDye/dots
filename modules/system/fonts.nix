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
        inputs.myFonts.packages.${system}.luxi-mono
        inputs.myFonts.packages.${system}.nordwand-mono
        pkgs.nerd-fonts._0xproto
        pkgs.nerd-fonts.fira-code
        pkgs.nerd-fonts.martian-mono
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
        # the home-manager scope and is not visible here). Nordwand Mono
        # carries Nerd Font icons in its patched TTFs. The shared fallback
        # chain adds Symbols Nerd Font Mono for icons (the only icon source
        # for Libertinus Serif), then Libertinus Math for math glyphs.
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
