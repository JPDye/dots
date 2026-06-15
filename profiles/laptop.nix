# Form-factor profile: settings shared by every laptop but not by desktops.
# A host imports exactly one of profiles/{laptop,desktop}.nix from its
# configuration.nix — the middle tier between the always-shared modules/ and a
# host's own per-machine divergence. Machine-specific values (resume_offset,
# nixos-hardware chassis profile, monitor outputs) still live in the host.
_:

{
  # Battery/TLP power management (charge thresholds, on-battery perf caps).
  # power.nix defaults this off so a bare desktop never inherits it; laptops
  # opt in here.
  dotfiles.system.power.enable = true;

  # Firmware updates via `fwupdmgr refresh && fwupdmgr update`. Laptops
  # (ThinkPads especially) publish BIOS/EC updates through LVFS; without this
  # they sit unapplied.
  services.fwupd.enable = true;
}
