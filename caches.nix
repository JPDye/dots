# Single source of truth for the extra binary caches used in two places that
# can't share a `let`: the flake's eval-time `nixConfig` (flake.nix) and the
# persistent system config (modules/system/nix.nix). Keeping the list here
# stops the two from silently drifting.
let
  # cache.nixos.org is already a default substituter, so it's only needed for
  # the persistent `substituters`/`trustedPublicKeys` lists — not the flake's
  # `extra-*` additions.
  cacheNixOrg = {
    url = "https://cache.nixos.org";
    key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
  };

  extra = [
    {
      url = "https://helix.cachix.org";
      key = "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=";
    }
    {
      url = "https://niri.cachix.org";
      key = "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=";
    }
  ];

  all = [ cacheNixOrg ] ++ extra;
in
{
  # For flake `nixConfig.extra-*` — the defaults already include cache.nixos.org.
  extraSubstituters = map (c: c.url) extra;
  extraTrustedPublicKeys = map (c: c.key) extra;

  # For persistent `nix.settings` — full lists including cache.nixos.org.
  substituters = map (c: c.url) all;
  trustedPublicKeys = map (c: c.key) all;
}
