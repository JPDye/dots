{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.apps.termius;
in
{
  options.dotfiles.apps.termius.enable = lib.mkEnableOption "termius ssh client" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    # Termius keeps its database key in the OS keyring and hangs on a blank
    # splash when no login keyring exists. On Arch run
    # `nix run .#arch-pam-setup` once (hosts/laptop-arch/pam-setup.nix).
    home.packages = [ pkgs.termius ];
  };
}
