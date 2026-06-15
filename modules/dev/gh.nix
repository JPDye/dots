{ config, lib, ... }:

let
  cfg = config.dotfiles.dev.gh;
in
{
  options.dotfiles.dev.gh.enable = lib.mkEnableOption "GitHub CLI" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.gh = {
      enable = true;
      # Must match the protocol `gh auth login --git-protocol` sets, or gh tries
      # to rewrite this file and fails: home-manager owns it as a store symlink.
      settings.git_protocol = "https";
    };
  };
}
