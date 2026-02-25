_:

{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Compressed RAM swap. Sits in front of any on-disk swap (higher priority
  # by default), so memory pressure compresses to RAM before touching the
  # SSD. Hibernate still resumes from the on-disk swap.
  zramSwap.enable = true;

  # NVMe TRIM. The t14s nixos-hardware profile doesn't pull in common/pc/ssd
  # (the t14 one does), so enable explicitly.
  services.fstrim.enable = true;
}
