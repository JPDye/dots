{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.dev.docker;
in
{
  # Rootless docker as a systemd user service, built from nixpkgs. The NixOS
  # hosts get rootless docker from modules/system/containers.nix. This module
  # exists for laptop-arch, where home-manager cannot manage system services.
  # Default off: on a NixOS host this unit would collide with the one from
  # virtualisation.docker.rootless on the same socket.
  #
  # Host prerequisites, all root-owned, all already true on laptop-arch:
  # /etc/subuid and /etc/subgid entries for the user, unprivileged user
  # namespaces on, and newuidmap from Arch's shadow package.
  options.dotfiles.dev.docker.enable = lib.mkEnableOption "rootless docker (user service)";

  config = lib.mkIf cfg.enable {
    home.packages = [
      # The client, dockerd, and the dockerd-rootless wrapper.
      pkgs.docker
      # Parity with the NixOS hosts, which install it system-wide.
      pkgs.docker-compose
    ];

    # This unit mirrors nixos/modules/virtualisation/docker-rootless.nix. The
    # dockerd-rootless wrapper carries rootlesskit, slirp4netns, iptables, and
    # dockerd on its own PATH. The setuid newuidmap must come from the host
    # system. Arch ships it in /usr/bin, which the user-unit PATH includes.
    systemd.user.services.docker = {
      Unit = {
        Description = "Docker Application Container Engine (rootless)";
        # dockerd-rootless refuses to run as root.
        ConditionUser = "!root";
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
      Service = {
        Type = "notify";
        ExecStart = "${pkgs.docker}/bin/dockerd-rootless";
        ExecReload = "${pkgs.procps}/bin/kill -s HUP $MAINPID";
        TimeoutSec = 0;
        RestartSec = 2;
        Restart = "always";
        LimitNOFILE = "infinity";
        LimitNPROC = "infinity";
        LimitCORE = "infinity";
        Delegate = true;
        NotifyAccess = "all";
        KillMode = "mixed";
      };
      Install.WantedBy = [ "default.target" ];
    };

    # The client defaults to /var/run/docker.sock, the rootful path. Set
    # DOCKER_HOST to the rootless socket, as setSocketVariable does on NixOS.
    home.sessionVariables.DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/docker.sock";

    # hm-session-vars.sh is POSIX, and nushell never sources it (see nh.nix),
    # so nushell needs its own copy of the variable.
    programs.nushell.environmentVariables.DOCKER_HOST = lib.hm.nushell.mkNushellInline ''$"unix://($env.XDG_RUNTIME_DIR)/docker.sock"'';
  };
}
