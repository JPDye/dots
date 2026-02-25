{ config, lib, ... }:

let
  cfg = config.dotfiles.shell.integrations;
in
{
  options.dotfiles.shell.integrations.enable =
    lib.mkEnableOption "shell integrations (zoxide/atuin/direnv/bat/eza/carapace)"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    programs = {
      zoxide = {
        enable = true;
        enableNushellIntegration = true;
        options = [ "--cmd cd" ];
      };

      carapace = {
        enable = true;
        enableNushellIntegration = true;
      };

      atuin = {
        enable = true;
        enableNushellIntegration = true;
        settings = {
          search_mode = "fuzzy";
        };
      };

      direnv = {
        enable = true;
        enableNushellIntegration = true;
        nix-direnv.enable = true;
        silent = true;
      };

      bat = {
        enable = true;
        config.pager = "less -FR";
      };

      eza = {
        enable = true;
        git = true;
        icons = "auto";
        extraOptions = [ "--group-directories-first" ];
      };
    };
  };
}
