# Source of truth for the extra binary caches used by the persistent system
# config (modules/system/nix.nix).
#
# NOTE: the flake's eval-time `nixConfig.extra-*` (flake.nix) CANNOT import
# this file — Nix requires nixConfig values to be literals (see the comment
# there). The `extra` list below is duplicated there as inline literals; if you
# add/remove/rekey a cache, update both. Everything else reads from here.
let
  # cache.nixos.org is already a default substituter, so it's only needed for
  # the persistent `substituters`/`trustedPublicKeys` lists — not the flake's
  # `extra-*` additions.
  cacheNixOrg = {
    url = "https://cache.nixos.org";
    key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
  };

  # KEEP IN SYNC with flake.nix's `nixConfig.extra-*` literals (it can't import
  # this file — see the NOTE above).
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
  # For persistent `nix.settings` (modules/system/nix.nix) — full lists
  # including cache.nixos.org.
  substituters = map (c: c.url) all;
  trustedPublicKeys = map (c: c.key) all;
}
