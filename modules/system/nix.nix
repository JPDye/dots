let
  # Shared with the flake's eval-time `nixConfig` (flake.nix) so the two
  # cache lists can't drift.
  caches = import ../../caches.nix;
in
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
      inherit (caches) substituters;
      trusted-public-keys = caches.trustedPublicKeys;
    };

    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
