_:

{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Compressed RAM swap. Sits in front of any on-disk swap (higher priority
  # by default), so memory pressure compresses to RAM before touching the
  # SSD. Hibernate still resumes from the on-disk swap. memoryPercent = 150
  # (vs the 50% default) keeps far more cold memory in fast compressed RAM
  # before anything spills to /swapfile, where disk paging stalls the whole
  # machine — 14 GB RAM thrashes the SSD under a browser + a workspace build.
  zramSwap = {
    enable = true;
    memoryPercent = 150;
  };

  # Reclaim file cache before swapping anonymous pages out (default is 60).
  # Lower swappiness means the kernel leans on dropping cache rather than
  # eagerly paging working-set memory, which reduces swap thrashing.
  boot.kernel.sysctl."vm.swappiness" = 10;

  # NVMe TRIM. The t14s nixos-hardware profile doesn't pull in common/pc/ssd
  # (the t14 one does), so enable explicitly.
  services.fstrim.enable = true;
}
