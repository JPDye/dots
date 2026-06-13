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
        fallbacks = [
          monoFont
          "FiraCode Nerd Font Mono"
        ];
      in
      {
        enable = true;
        defaultFonts = {
          monospace = fallbacks;
          # serif + sansSerif resolve to Lora, then fall back to the mono
          # Nerd Fonts for glyphs Lora lacks (icons, odd unicode).
          serif = [ serifFont ] ++ fallbacks;
          sansSerif = [ serifFont ] ++ fallbacks;
        };
      };

    home.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.symbols-only
      cascadia-code
      helvetica-neue-lt-std
      lora
      siji

      inputs.myFonts.packages.${pkgs.stdenv.hostPlatform.system}.ioskeley
    ];
  };
}
