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
  ];

  networking.hostName = "@HOSTNAME@";

  # installer:luks (line replaced with boot.initrd.luks config, or deleted, by install-host.sh)

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Don't touch unless you know what you're doing.
  system.stateVersion = "@STATE_VERSION@";
}
