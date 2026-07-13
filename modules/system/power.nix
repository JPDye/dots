{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.system.power;
in
{
  # Default OFF: this is laptop-only (battery charge thresholds, on-battery perf
  # caps), so a bare desktop must not inherit it. profiles/laptop.nix opts in.
  options.dotfiles.system.power.enable =
    lib.mkEnableOption "laptop power management (tlp + upower + poweralertd)";

  config = lib.mkIf cfg.enable {
    services.tlp = {
      enable = true;
      settings = {
        # `powersave` is the EPP-aware governor under amd_pstate=active —
        # actual behaviour is driven by CPU_ENERGY_PERF_POLICY below.
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 60;

        # Turbo off on battery — pairs with the relaxed MAX_PERF cap above.
        CPU_BOOST_ON_BAT = 0;

        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    services.upower = {
      enable = true;
      usePercentageForPolicy = true;
      percentageLow = 20;
      percentageCritical = 10;
      percentageAction = 5;
      criticalPowerAction = "Hibernate";
    };

    systemd.user.services.poweralertd = {
      description = "Power alert daemon (UPower → desktop notifications)";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.poweralertd}/bin/poweralertd";
        Restart = "on-failure";
      };
    };
  };
}
