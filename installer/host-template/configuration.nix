# Stamped into hosts/<name>/ by the installer ISO (installer/install-host.sh
# fills the @PLACEHOLDERS@ and drops a generated hardware-configuration.nix
# alongside). Machine-specific extras — a nixos-hardware profile, swapfile +
# hibernate resume offset — are opt-in afterwards; crib from
# hosts/laptop-nix/configuration.nix.
_:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/system

    # Pick a form-factor profile once you know the machine — laptops get
    # TLP/fwupd, desktops don't. See hosts/{laptop-nix,nix-desktop}/configuration.nix.
    #   ../../profiles/laptop.nix
    #   ../../profiles/desktop.nix
  ];

  networking.hostName = "@HOSTNAME@";

  # installer:luks (line replaced with boot.initrd.luks config, or deleted, by install-host.sh)

  # Don't touch unless you know what you're doing.
  system.stateVersion = "@STATE_VERSION@";
}
