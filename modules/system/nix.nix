let
  # Source of truth for the cache list. The flake's `nixConfig` (URLs only),
  # the CI workflow and the README repeat it, and `caches-in-sync` fails
  # `nix flake check` if any copy drifts.
  caches = import ../../caches.nix;
in
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
      # access, so that trust must not exist. The caches below are system-wide,
      # so no user needs it for cache hits.

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
