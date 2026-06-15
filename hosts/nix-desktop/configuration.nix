# Stamped into hosts/<name>/ by the installer ISO (installer/install-host.sh
# fills the @PLACEHOLDERS@ and drops a generated hardware-configuration.nix
# alongside). Machine-specific extras — a nixos-hardware profile, swapfile +
# hibernate resume offset — are opt-in afterwards; crib from
# hosts/laptop-nix/configuration.nix.
{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/system

    # Form factor: this is a desktop (no battery/TLP, no laptop firmware quirks).
    ../../profiles/desktop.nix

    # Generic Intel desktop (i7-5820K, Haswell-E): microcode + sensible CPU
    # defaults. No chassis profile — this is a bare ASUS desktop, not a laptop.
    inputs.nixos-hardware.nixosModules.common-cpu-intel
  ];

  networking.hostName = "nix-desktop";

  # /nix and /home live on the 1TB sdb (btrfs, one filesystem, two subvolumes).
  # sda holds only / and /boot. btrfs is needed in the initrd because /nix is
  # required for early boot. Swap stays on the sda root (/swapfile) — btrfs
  # swapfiles are finicky and complicate hibernate resume offsets.
  boot = {
    supportedFilesystems = [ "btrfs" ];

    # Hibernate from /swapfile on the sda root partition.
    # If /swapfile gets fragmented, defrag and re-derive resume_offset:
    #   sudo filefrag -v /swapfile | awk 'NR==4 {gsub(/\.\./, " "); print $4}'
    resumeDevice = "/dev/disk/by-uuid/ea6e6e01-3bba-409c-8235-3560fd1a1536";
    kernelParams = [ "resume_offset=3266560" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/f944d39f-3497-4e56-b9d2-4a5286622330";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/f944d39f-3497-4e56-b9d2-4a5286622330";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
      "noatime"
    ];
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 18 * 1024;
    }
  ];

  # Don't touch unless you know what you're doing.
  system.stateVersion = "26.11";
}
