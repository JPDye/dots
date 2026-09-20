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

  boot.kernel.sysctl = {
    # Reclaim file cache before swapping anonymous pages out (default is 60).
    # Lower swappiness means the kernel leans on dropping cache rather than
    # eagerly paging working-set memory, which reduces swap thrashing.
    "vm.swappiness" = 10;

    # Start reclaim earlier. The default of 10 keeps only 0.1% of the zone as
    # headroom, so the kernel reaches the allocation cliff before it has freed
    # anything, and that is where the stalls come from. 125 raises the
    # headroom to 1.25% of the zone.
    "vm.watermark_scale_factor" = 125;
  };

  # systemd-oomd runs by default on NixOS, but every slice toggle defaults to
  # false, so it monitors no cgroup and kills nothing. That leaves the kernel
  # OOM killer as the only backstop, and it fires only after the machine has
  # already thrashed for minutes. Fedora enables the root and the user slices,
  # and so does this.
  #
  # The user-manager half of enableUserSlices is inert: it writes its drop-in
  # for a unit named `slice`, and systemd has no unit by that name. The
  # graphical session is covered by modules/desktop/oomd.nix instead, which is
  # home-manager-scoped and so also reaches laptop-arch.
  systemd.oomd = {
    enableRootSlice = true;
    enableUserSlices = true;
    settings.OOM = {
      # Act on swap exhaustion, not on stall alone. zram fills long before the
      # pressure limit trips, and a full zram is what precedes the freeze.
      SwapUsedLimit = "90%";
      DefaultMemoryPressureLimit = "60%";
      DefaultMemoryPressureDurationSec = "20s";
    };
  };

  # nixpkgs' oomd module sets ManagedOOMMemoryPressure on the slices it
  # enables, but it never sets ManagedOOMSwap, so SwapUsedLimit above would
  # have no candidate to act on. Marking the root slice makes every cgroup a
  # candidate.
  systemd.slices."-".sliceConfig = {
    ManagedOOMSwap = "kill";
    # nixpkgs sets 80% here through mkDefault. 60% matches app.slice in
    # modules/desktop/oomd.nix and /etc/systemd/oomd.conf on laptop-arch.
    ManagedOOMMemoryPressureLimit = "60%";
  };

  # NVMe TRIM. The t14s nixos-hardware profile doesn't pull in common/pc/ssd
  # (the t14 one does), so enable explicitly.
  services.fstrim.enable = true;
}
