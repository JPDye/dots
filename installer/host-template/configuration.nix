# Stamped into hosts/<name>/ by the installer ISO (installer/install-host.sh
# rewrites the `# installer:*` marker lines and drops a generated
# hardware-configuration.nix alongside). The values below are eval-only
# placeholders, so `nix flake check` can evaluate this template
# (flake.nix's `installer-template` check) before any real install.
# install-host.sh stamps the form-factor profile and the swapfile plus
# hibernate offset from its own prompts. A nixos-hardware chassis profile
# still needs adding by hand: crib from hosts/laptop-nix/configuration.nix.
_:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/system

    # installer:profile (replaced with a ../../profiles/<form-factor>.nix import, or deleted, by install-host.sh)
  ];

  networking.hostName = "host-template"; # installer:hostname

  # installer:luks (line replaced with boot.initrd.luks config, or deleted, by install-host.sh)

  # installer:swap (replaced with swapDevices + hibernate resume config, or deleted, by install-host.sh)

  # Don't touch unless you know what you're doing.
  system.stateVersion = "26.05"; # installer:state-version
}
