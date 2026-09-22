{
  config,
  lib,
  pkgs,
  inputs,
  colors,
  ...
}:

let
  cfg = config.dotfiles.apps.spicetify;
in
{
  options.dotfiles.apps.spicetify.enable = lib.mkEnableOption "spicetify spotify theme" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.spicetify =
      let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        enable = true;

        theme = lib.mkForce spicePkgs.themes.text;
        customColorScheme = lib.mkForce {
          "accent" = "${colors.accent}";
          "accent-active" = "${colors.urgent}";
          "accent-inactive" = "${colors.bg3}";
          "banner" = "${colors.accent}";
          # In-app element outlines follow the niri window border, so a
          # focused thing reads the same whether it is a window, a pane or
          # a panel inside an app.
          "border-active" = "${colors.borderActive}";
          "border-inactive" = "${colors.bg2}";
          "header" = "${colors.accent}";
          "highlight" = "${colors.urgent}";
          "main" = "${colors.bg0}";
          "notification" = "${colors.info}";
          "notification-error" = "${colors.urgent}";
          "subtext" = "${colors.accent}";
          "text" = "${colors.fg0}";
        };
      };
  };
}
