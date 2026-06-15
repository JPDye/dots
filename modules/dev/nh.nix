{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.dev.nh;
in
{
  options.dotfiles.dev.nh.enable = lib.mkEnableOption "nh nix helper + nix-output-monitor" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      # Plain filesystem string — re-read on each `nh os switch`. Avoid
      # `inputs.self.outPath`, which freezes to the store path of the
      # flake at build time and would make nh ignore working-tree edits.
      flake = "${config.home.homeDirectory}/.config/nix";
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 5";
      };
    };

    home.packages = [ pkgs.nix-output-monitor ];
  };
}
