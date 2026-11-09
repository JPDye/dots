# The font packages both fontconfig setups install, and their shared
# fallback chain. A plain function, not a module, for the same reason as
# palette.nix: modules/system/fonts.nix (NixOS scope) and
# modules/theming/fonts.nix (home-manager scope) both import it. Each
# module adds its own extras on top of `common`.
{ pkgs, myFonts }:
{
  common = [
    myFonts.ioskeley
    myFonts.drafting-mono
    myFonts.luxi-mono
    myFonts.nordwand-mono
    pkgs.nerd-fonts._0xproto
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.martian-mono
    pkgs.nerd-fonts.droid-sans-mono
    pkgs.nerd-fonts.symbols-only
    pkgs.libertinus # Serif text face + Math symbols (see fallbacks)
    pkgs.lora
  ];

  # Nordwand Mono carries the Nerd Font icon set in its patched TTFs, so the
  # mono chain needs only Libertinus Math for math glyphs. Libertinus Serif
  # has no icons, so the serif chains take them from Symbols Nerd Font Mono.
  fallbacks = [
    "Symbols Nerd Font Mono"
    "Libertinus Math"
  ];
}
