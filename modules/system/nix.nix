_:

{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "jd"
      ];

      # 256 MiB — default 64 MiB warns "downloaded more than buffer size" on
      # larger fetches (e.g. cuda/electron closures). Store dedup is handled
      # by `nix.optimise.automatic` below, not the on-write `auto-optimise-store`.
      download-buffer-size = 268435456;

      # Trust the niri/helix binary caches system-wide so non-root users
      # don't need to be in trusted-users to use them.
      substituters = [
        "https://cache.nixos.org"
        "https://helix.cachix.org"
        "https://niri.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };

    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
