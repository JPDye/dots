{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # No trusted-users beyond the NixOS default, root. A trusted user can
      # feed the daemon unsigned store paths and arbitrary substituters, which
      # the Nix manual calls root-equivalent. jd runs coding agents with shell
      # access, so that trust must not exist. No user needs it: the only cache
      # is cache.nixos.org, which every user can use.

      # 256 MiB — default 64 MiB warns "downloaded more than buffer size" on
      # larger fetches (e.g. cuda/electron closures). Store dedup is handled
      # by `nix.optimise.automatic` below, not the on-write `auto-optimise-store`.
      download-buffer-size = 268435456;
    };

    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
