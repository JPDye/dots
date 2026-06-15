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
      settings.git_protocol = "ssh";
    };
  };
}
