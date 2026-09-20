{ config, lib, ... }:
let
  cfg = config.dotfiles.desktop.oomd;
in
{
  options.dotfiles.desktop.oomd.enable =
    lib.mkEnableOption "systemd-oomd memory-pressure kills for graphical apps"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    # systemd-oomd acts only on cgroups that opt in, and nothing opts in by
    # default. Without this the kernel OOM killer is the only backstop, and it
    # fires only after the machine has already thrashed for minutes. On
    # laptop-arch it killed Slack on 2026-09-03, well after the freeze.
    #
    # niri puts every app in its own scope under app.slice
    # (app-niri-<name>-<pid>.scope), so a limit set on app.slice reaches all of
    # them. oomd then kills the single worst app, not the session.
    #
    # This lives here rather than in modules/system/boot.nix for two reasons.
    # laptop-arch has no NixOS layer at all, so a system module would skip it.
    # And nixpkgs' own systemd.oomd.enableUserSlices does not cover this: it
    # writes its user-manager drop-in for a unit named `slice`, and systemd has
    # no unit by that name, so that half is inert. boot.nix still handles the
    # NixOS-only half (the root slice, swap, and the sysctls).
    #
    # A drop-in, not a unit. app.slice is a systemd built-in, and a file of
    # that name in ~/.config/systemd/user would replace it outright.
    xdg.configFile."systemd/user/app.slice.d/oomd.conf".text = ''
      [Slice]
      ManagedOOMMemoryPressure=kill
      ManagedOOMMemoryPressureLimit=60%
    '';
  };
}
