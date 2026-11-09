{ config, lib, ... }:

let
  cfg = config.dotfiles.desktop.poweralertd;
in
{
  options.dotfiles.desktop.poweralertd.enable =
    lib.mkEnableOption "poweralertd battery and power-supply notifications"
    // {
      default = true;
    };

  # poweralertd subscribes to UPower over D-Bus. It sends a desktop
  # notification (mako renders it) when a battery's warning level changes
  # (low, critical, action), or when a power supply goes online or offline.
  # It finds the battery through UPower, so the kernel name (BAT0 on one
  # laptop, BAT1 on another) does not matter.
  #
  # The thresholds are UPower's, not poweralertd's. On NixOS they come from
  # services.upower in modules/system/power.nix (low 20%, critical 10%,
  # action 5%). On Arch they come from /etc/UPower/UPower.conf, which this
  # flake does not manage (the package default is low 20%, critical 5%,
  # action 2%).
  #
  # This is a home-manager module, not part of modules/system/power.nix, so
  # that laptop-arch gets it too: that host imports no NixOS module. On a
  # host with no battery (the desktop) the unit skips itself, because
  # poweralertd exits when UPower has no battery to report. The test reads
  # the same directory that modules/desktop/lock.nix reads. Peripheral
  # batteries (mice, headsets) have other names, so BAT* matches only a
  # laptop battery.
  config = lib.mkIf cfg.enable {
    services.poweralertd = {
      enable = true;
      # Without -s, poweralertd sends one notification per power-supply
      # device at every start, so at every login, to report the current
      # state. Only the changes after start are useful.
      extraArgs = [ "-s" ];
    };

    systemd.user.services.poweralertd.Unit.ConditionPathExistsGlob = "/sys/class/power_supply/BAT*";
  };
}
