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
      pkgs.nerd-fonts.fira-code
      pkgs.nerd-fonts.droid-sans-mono
      pkgs.nerd-fonts.commit-mono
      pkgs.input-fonts
      pkgs.lora
      pkgs.font-awesome
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "IoskeleyMono Nerd Font"
          "Fira Code Nerd Font Mono"
        ];
        serif = [
          "IoskeleyMono Nerd Font"
          "Fira Code Nerd Font Mono"
        ];
        sansSerif = [
          "IoskeleyMono Nerd Font"
          "Fira Code Nerd Font Mono"
        ];
      };
    };
  };
}
