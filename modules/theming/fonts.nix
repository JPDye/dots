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

  config = lib.mkIf cfg.enable {
    fonts.fontconfig =
      let
        # Nordwand Mono carries the Nerd Font icon set in its patched TTFs,
        # so the mono chain falls through only to Libertinus Math for math
        # glyphs. Libertinus Serif has no icons, so the serif chains take
        # them from Symbols Nerd Font Mono.
        fallbacks = [
          "Symbols Nerd Font Mono"
          "Libertinus Math"
        ];
      in
      {
        enable = true;
        defaultFonts = {
          monospace = [ monoFont ] ++ fallbacks;
          serif = [ serifFont ] ++ fallbacks;
          sansSerif = [ serifFont ] ++ fallbacks;
        };
      };

    home.packages = with pkgs; [
      nerd-fonts._0xproto
      nerd-fonts.fira-code
      nerd-fonts.martian-mono
      nerd-fonts.droid-sans-mono
      nerd-fonts.symbols-only
      libertinus # Serif text face + Math symbols (see fallbacks above)
      cascadia-code
      lora
      siji

      inputs.myFonts.packages.${pkgs.stdenv.hostPlatform.system}.ioskeley
      inputs.myFonts.packages.${pkgs.stdenv.hostPlatform.system}.drafting-mono
      inputs.myFonts.packages.${pkgs.stdenv.hostPlatform.system}.luxi-mono
      inputs.myFonts.packages.${pkgs.stdenv.hostPlatform.system}.nordwand-mono
    ];
  };
}
