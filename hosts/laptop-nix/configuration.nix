{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/system

    # No exact T14s Gen 3 AMD profile in nixos-hardware. Combine the closest
    # chassis match (t14s-amd-gen1 — same form factor, deep sleep tweak) with
    # the AMD pstate driver (big battery win on Ryzen 6000-series).
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s-amd-gen1
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
  ];

  networking.hostName = "laptop-nix";

  # Hibernate from /swapfile on the root partition.
  # If /swapfile gets fragmented, defrag and re-derive resume_offset:
  #   sudo filefrag -v /swapfile | awk 'NR==4 {gsub(/\.\./, " "); print $4}'
  boot = {
    resumeDevice = "/dev/disk/by-uuid/38ce82b2-1685-4681-b9ac-35f9d1e2e995";
    kernelParams = [ "resume_offset=117575680" ];
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 18 * 1024; # MiB; ≥ RAM (14Gi) + headroom
    }
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    libGL
    libGLU
    mesa
  ];

  # Don't touch unless you know what you're doing.
  system.stateVersion = "25.11";
}
