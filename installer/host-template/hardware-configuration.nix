# Eval-only stub so the flake's `installer-template` check can evaluate the
# template. install-host.sh never copies this file: it generates the real
# hardware-configuration.nix on the target machine with nixos-generate-config.
{ lib, ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
