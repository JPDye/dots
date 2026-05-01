{ pkgs, inputs, system, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

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

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    upower = {
      enable = true;
      percentageLow = 20;
      percentageCritical = 10;
      percentageAction = 5;
      criticalPowerAction = "Hibernate";
    };

    blueman.enable = true;

    pipewire = {
      enable = true;
      pulse.enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;
    };

    xserver.xkb.layout = "gb";
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
    hostName = "jd-nix";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    networkmanager.enable = true;
    firewall.allowedUDPPorts = [ 53 51820 41641 ];
  };

  # Users
  users.users.jd = {
    shell = pkgs.nushell;
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "wireshark" ];
  };

  # Keymap
  console.keyMap = "uk";
  i18n.defaultLocale = "en_GB.UTF-8";

  # Windowing
  programs.niri.enable = true;

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark-cli;
  };

  # Sound
  security.rtkit.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
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
    packages = with pkgs; [
      inputs.myFonts.packages.${system}.ioskeley
      inputs.myFonts.packages.${system}.berkeley
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
        monospace = [ "IoskeleyMono Nerd Font" "Fira Code Nerd Font Mono" ];
        serif = [ "IoskeleyMono Nerd Font" "Fira Code Nerd Font Mono" ];
        sansSerif = [ "IoskeleyMono Nerd Font" "Fira Code Nerd Font Mono" ];
      };
    };
  };

  # Don't touch unless you know what you're doing.
  system.stateVersion = "25.11";
}
