{ config, lib, pkgs, inputs, ... }:

let
  colors = {
    # Background colors
    bg0 = "1c1c1c";
    bg1 = "3c3836";
    bg2 = "504945";
    bg3 = "665c54";

    mid = "463030";

    # Foreground colors
    fg3 = "bdae93";
    fg2 = "d5c4a1";
    fg1 = "ebdbb2";
    fg0 = "fbf1c7";

    # Named colors
    white = "D0D0BA";
    grey = "878787";
    red = "af5f5f";
    green = "87875f";
    yellow = "AFA45F";
    orange = "af875f";
    blue = "87afaf";
    pink = "af8787";


    # Semantic colors (easy to change theme)
    primary = "af5f5f";      # Red - main UI elements, borders, active states
    secondary = "af875f";    # Orange - highlights, headers, accents
    accent = "87875f";       # Green - additional highlights
  };
in
{
  imports = [
    ./hardware-configuration.nix
    inputs.spicetify-nix.nixosModules.spicetify
  ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Home Manager
  home-manager = {
    extraSpecialArgs = { inherit inputs; inherit colors; };
    backupFileExtension = "old_backup_file";
    users = {
      "jd" = import ./home.nix;
    };

    sharedModules = [
      inputs.stylix.homeModules.stylix
      inputs.nixcord.homeModules.nixcord
      inputs.textfox.homeManagerModules.textfox
    ];
  };


  # swww
  systemd.user.services.swww = {
    description = "swww daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.swww}/bin/swww-daemon";
      Restart = "always";
    };
  };

  # ew
  systemd.user.services.eww = {
    description = "eww daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target"];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
      Restart = "always";
    };
  };

  systemd.user.services.eww-powermenu = {
    description = "eww powermenu/bar toggle";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "eww.service" "graphical-session.target" ];
    wants = [ "eww.service" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.nushell}/bin/nu /home/jd/.config/eww/powermenu.nu";
      Restart = "always";
    };
    path = [ pkgs.eww pkgs.niri ];
  };


  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Clock
  time.timeZone = "Europe/London";

  services.dbus = {
    enable = true;
    packages = with pkgs; [
      dbus
      blueman
      xdg-desktop-portal
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome 
    ];
  };

  services.tlp = {
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

  services.upower = {
    enable = true;
    percentageLow = 20;
    percentageCritical = 10;
    percentageAction = 5;
    criticalPowerAction = "Hibernate";
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];

    config.common.default = "gtk";
  };

  # Networking
  networking.hostName = "jd-nix";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
  networking.networkmanager.enable = true;
  networking.firewall.checkReversePath = false;
  networking.firewall = {
    allowedUDPPorts = [ 53 51820 ];
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
  services.xserver.xkb.layout = "gb";

  # Windowing
  programs.niri = {
    enable = true;
  };

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark-cli;
  };

  programs.spicetify =
  let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  in
  {
    enable = true;

    theme = lib.mkForce spicePkgs.themes.text;
    customColorScheme = lib.mkForce {
      "accent"             = "${colors.secondary}";
      "accent-active"      = "${colors.primary}";
      "accent-inactive"    = "${colors.bg3}";
      "banner"             = "${colors.secondary}";
      "border-active"      = "${colors.primary}";
      "border-inactive"    = "${colors.bg2}";
      "header"             = "${colors.secondary}";
      "highlight"          = "${colors.primary}";
      "main"               = "${colors.bg0}";
      "notification"       = "458588";
      "notification-error" = "cc241d";
      "subtext"            = "${colors.secondary}";
      "text"               = "${colors.fg0}";
    };
  };

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # Bluetooth
  # hardware.bluetooth = {
  #   enable = true;
  #   powerOnBoot = true;
  # };

  # services.blueman.enable = true;

  # System-wide packages
  nixpkgs.config.allowUnfree = true;

  # OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    chromium

    xwayland-satellite
    spotify

    ## OpenGL
    libGL
    libGLU
    mesa

    ffmpeg

    # Terminal necessities and utilities
    git         # Version control
    zellij      # Multiplexing
    
    bat         # Faster and better `cat`
    bottom      # Prettier `htop`
    ripgrep     # Super fast `grep`
    tokei       # Count lines of code
    hyperfine   # Benchmark commands
    unzip       # Unzip stuff
    tree        # Get directory structure

    wireshark-qt

    # Development necessities
    docker-compose

    # Sound
    pavucontrol

    # Wallpapers
    swaybg
    swww
    brightnessctl

    foliate

    steam

    orca-slicer

    inputs.claude-code.packages.${system}.default

    wireguard-tools
    protonvpn-gui

    sccache
    ];


  environment.sessionVariables = {
    RUSTC_WRAPPER = "sccache";
  };    

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
      pkgs.nerd-fonts.fira-code
      pkgs.nerd-fonts.droid-sans-mono
      pkgs.lora
    ];


    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = ["DroidSans Mono"];
      };
    };
  };

  # Don't touch unless you know what you're doing.
  system.stateVersion = "25.11";
}
