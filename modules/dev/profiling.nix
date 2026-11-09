{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.dev.profiling;
in
{
  options.dotfiles.dev.profiling.enable = lib.mkEnableOption "perf and samply profilers" // {
    default = true;
  };

  # cargo-flamegraph lives in each project's dev shell, but it drives the
  # perf binary, which no shell carries. One perf here serves every shell.
  # samply samples a process and opens the result in the Firefox Profiler.
  # Both need kernel.perf_event_paranoid at 1 or lower: modules/system/boot.nix
  # sets it on NixOS, and README.md says how to set it on Arch.
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      perf
      samply
    ];
  };
}
