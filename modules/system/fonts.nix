{
  pkgs,
  inputs,
  system,
  ...
}:

{
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
      # This NixOS-scoped module can't see theme.nix's monoFont arg (that lives
      # in the home-manager scope), so the family is spelled out — keep it in
      # sync with modules/theming/theme.nix. Drafting Mono lacks icon/math
      # glyphs, so every category shares the same fallback chain: Nerd Font
      # symbols (icons) then Libertinus Math. No serif fallback — all Drafting
      # Mono.
      defaultFonts =
        let
          fallbacks = [
            "Symbols Nerd Font Mono"
            "Libertinus Math"
          ];
        in
        {
          monospace = [ "Drafting Mono" ] ++ fallbacks;
          serif = [ "Drafting Mono" ] ++ fallbacks;
          sansSerif = [ "Drafting Mono" ] ++ fallbacks;
        };
    };
  };
}
