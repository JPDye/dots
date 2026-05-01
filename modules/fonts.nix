{ pkgs, inputs, monoFont, ... }:

{
  fonts.fontconfig =
    let
      fallbacks = [ monoFont "Berkeley Mono Variable" "FiraCode Nerd Font Mono" ];
    in
    {
      enable = true;
      defaultFonts = {
        monospace = fallbacks;
        serif = fallbacks;
        sansSerif = fallbacks;
      };
    };

  home.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.symbols-only
    cascadia-code
    helvetica-neue-lt-std
    siji

    inputs.myFonts.packages.${pkgs.stdenv.hostPlatform.system}.berkeley
    inputs.myFonts.packages.${pkgs.stdenv.hostPlatform.system}.ioskeley
  ];
}
