{ lib, pkgs, inputs, colors, ... }:

{
  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;

      theme = lib.mkForce spicePkgs.themes.text;
      customColorScheme = lib.mkForce {
        "accent" = "${colors.orange}";
        "accent-active" = "${colors.red}";
        "accent-inactive" = "${colors.bg3}";
        "banner" = "${colors.orange}";
        "border-active" = "${colors.red}";
        "border-inactive" = "${colors.bg2}";
        "header" = "${colors.orange}";
        "highlight" = "${colors.red}";
        "main" = "${colors.bg0}";
        "notification" = "458588";
        "notification-error" = "cc241d";
        "subtext" = "${colors.orange}";
        "text" = "${colors.fg0}";
      };
    };
}
