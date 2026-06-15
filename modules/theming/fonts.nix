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
        # IoskeleyMono ships as a Nerd Font (icons built in), so the only real
        # fall-through is Libertinus Math for math glyphs; Symbols Nerd Font
        # Mono stays as a belt-and-braces icon backup. No serif fallback — the
        # desktop is all IoskeleyMono.
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
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.symbols-only
      libertinus # Serif text backup + Math symbols (see fallbacks above)
      cascadia-code
      helvetica-neue-lt-std
      lora
      siji

      inputs.myFonts.packages.${pkgs.stdenv.hostPlatform.system}.ioskeley
      inputs.myFonts.packages.${pkgs.stdenv.hostPlatform.system}.drafting-mono
    ];
  };
}
