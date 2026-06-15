{ config, lib, ... }:

let
  cfg = config.dotfiles.apps.nixcord;
in
{
  options.dotfiles.apps.nixcord.enable = lib.mkEnableOption "discord (via nixcord)" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.nixcord = {
      enable = true;

      # Use Vesktop instead of the official Discord binary: nixpkgs' discord
      # package is broken (its installPhase brotli-decodes the main app, but
      # Discord now ships it as a gzip tarball → "corrupt input"/tar failure).
      # Vesktop is a standalone Electron client that dodges that path entirely,
      # and Vencord config + stylix theming below apply to it unchanged.
      discord.enable = false;
      vesktop.enable = true;

      config = {
        # Pinned to the LAST system24 commit that still ships the gruvbox-material
        # flavour — upstream deleted it in 41037eed (2025-04-19), so `blob/main`
        # 404s. The pin both restores a working link and freezes the CSS Vencord
        # fetches at Discord runtime. Caveat: this CSS is from 2024-10; if Discord
        # DOM changes break it, either vendor a patched copy into the flake or
        # switch themeLinks to a surviving flavour (theme/flavors/system24-*).
        themeLinks = [
          "https://github.com/refact0r/system24/blob/c3c029dd8d6154eede54bceea9e997c721580688/theme/flavors/gruvbox-material.theme.css"
        ];
      };
    };
  };
}
