{ config, lib, ... }:

let
  cfg = config.dotfiles.shell.nixIndex;
in
{
  options.dotfiles.shell.nixIndex.enable =
    lib.mkEnableOption "nix-index + comma (run uninstalled binaries with `, cmd`)"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    # The file database comes prebuilt from the nix-index-database flake
    # module (imported in home.nix) — no local `nix-index` crawl needed.
    programs = {
      nix-index = {
        enable = true;
        # The Nushell command_not_found hook runs nix-locate over the whole
        # ~100 MB database on every typo, so an unknown command takes seconds
        # to fail. Keep the hook off. `, cmd` and `nix-locate` still work.
        enableNushellIntegration = false;
      };
      nix-index-database.comma.enable = true;
    };
  };
}
