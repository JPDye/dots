{ pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  virtualisation.podman.enable = true;

  environment.systemPackages = [ pkgs.docker-compose ];
}
