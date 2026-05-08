{
  pkgs,
  inputs,
  system,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix

    # No exact T14s Gen 3 AMD profile in nixos-hardware. Combine the closest
    # chassis match (t14s-amd-gen1 — same form factor, deep sleep tweak) with
    # the AMD pstate driver (big battery win on Ryzen 6000-series).
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s-amd-gen1
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "jd"
      ];
      auto-optimise-store = true;

      # Trust the niri/helix binary caches system-wide so non-root users
      # don't need to be in trusted-users to use them.
      substituters = [
        "https://cache.nixos.org"
        "https://helix.cachix.org"
        "https://niri.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };

    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Bootloader + hibernate from /swapfile on the root partition.
  # If /swapfile gets fragmented, defrag and re-derive resume_offset:
  #   sudo filefrag -v /swapfile | awk 'NR==4 {gsub(/\.\./, " "); print $4}'
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    resumeDevice = "/dev/disk/by-uuid/38ce82b2-1685-4681-b9ac-35f9d1e2e995";
    kernelParams = [ "resume_offset=117575680" ];
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 18 * 1024; # MiB; ≥ RAM (14Gi) + headroom
    }
  ];

  # Compressed RAM swap. Sits in front of the on-disk swapfile (higher
  # priority by default), so memory pressure compresses to RAM before
  # touching the SSD. Hibernate still resumes from /swapfile.
  zramSwap.enable = true;

  # Clock
  time.timeZone = "Europe/London";

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    dbus = {
      enable = true;
      packages = with pkgs; [
        dbus
        blueman
        xdg-desktop-portal
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
    };

    tlp = {
      enable = true;
      settings = {
        # `powersave` is the EPP-aware governor under amd_pstate=active —
        # actual behaviour is driven by CPU_ENERGY_PERF_POLICY below.
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 60;

        # Turbo off on battery — pairs with the relaxed MAX_PERF cap above.
        CPU_BOOST_ON_BAT = 0;

        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    upower = {
      enable = true;
      usePercentageForPolicy = true;
      percentageLow = 20;
      percentageCritical = 10;
      percentageAction = 5;
      criticalPowerAction = "Hibernate";
    };

    blueman.enable = true;

    gnome.gnome-keyring.enable = true;

    # NVMe TRIM. The t14s nixos-hardware profile doesn't pull in common/pc/ssd
    # (the t14 one does), so enable explicitly.
    fstrim.enable = true;

    pipewire = {
      enable = true;
      pulse.enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;
    };

    xserver.xkb.layout = "gb";
  };

  systemd.user.services.poweralertd = {
    description = "Power alert daemon (UPower → desktop notifications)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.poweralertd}/bin/poweralertd";
      Restart = "on-failure";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];

    configPackages = [ pkgs.niri ];

    config.common.default = "gtk";
  };

  # Networking
  networking = {
    hostName = "laptop-nix";
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    networkmanager = {
      enable = true;
      dns = "none";
      wifi.powersave = true;
    };
    firewall.allowedUDPPorts = [
      51820
      41641
    ];
  };

  # Users
  users.users.jd = {
    shell = pkgs.nushell;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "wireshark"
    ];
  };

  programs = {
    # The command-not-found handler hooks bash/zsh only — disabled because
    # the login shell above is nushell. Keeps the ~80MB sqlite index out of
    # every system closure.
    command-not-found.enable = false;

    niri.enable = true;

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
        fuse3
        icu
        nss
        nspr
        libGL
      ];
    };

    gpu-screen-recorder.enable = true;

    wireshark = {
      enable = true;
      package = pkgs.wireshark-cli;
    };
  };

  # Keymap
  console.keyMap = "uk";
  i18n.defaultLocale = "en_GB.UTF-8";

  # Sound
  security.rtkit.enable = true;

  # Bluetooth — Experimental enables battery reporting for headphones.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };

  # System-wide packages
  nixpkgs.config.input-fonts.acceptLicense = true;

  # OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    tailscale

    git

    ## OpenGL
    libGL
    libGLU
    mesa

    # pairs with virtualisation.docker
    docker-compose
  ];

  # Docker
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  virtualisation.podman.enable = true;

  # System Font
  fonts = {
    packages = [
      inputs.myFonts.packages.${system}.ioskeley
      pkgs.nerd-fonts.fira-code
      pkgs.nerd-fonts.droid-sans-mono
      pkgs.nerd-fonts.commit-mono
      pkgs.input-fonts
      pkgs.lora
      pkgs.font-awesome
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "IoskeleyMono Nerd Font"
          "Fira Code Nerd Font Mono"
        ];
        serif = [
          "IoskeleyMono Nerd Font"
          "Fira Code Nerd Font Mono"
        ];
        sansSerif = [
          "IoskeleyMono Nerd Font"
          "Fira Code Nerd Font Mono"
        ];
      };
    };
  };

  # Don't touch unless you know what you're doing.
  system.stateVersion = "25.11";
}
