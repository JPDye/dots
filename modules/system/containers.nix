{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.system.containers;
in
{
  options.dotfiles.system.containers.enable =
    lib.mkEnableOption "container runtimes (rootless docker + podman)"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      # Rootless only. The rootful daemon ran as root at boot but was unused:
      # jd is not in a `docker` group, and setSocketVariable points DOCKER_HOST
      # at the rootless socket. Keep it off to drop the root-owned daemon/socket.
      enable = false;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };

    virtualisation.podman.enable = true;

    environment.systemPackages = [ pkgs.docker-compose ];
  };
}
