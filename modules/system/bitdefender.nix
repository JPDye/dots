{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.system.bitdefender;

  dir = "/opt/bitdefender-security-tools";

  # Bitdefender does not support NixOS. The vendor package is a .deb that
  # installs FHS binaries into /opt and drops units into /etc/systemd/system.
  # /opt is mutable, so the binaries stay where the product expects them and
  # keep working with the built-in integrity check and the self-updater.
  # /etc/systemd/system is a read-only store symlink, so the units below are
  # transcribed from the package instead of installed by it.
  #
  # See hosts/laptop-nix/bitdefender/bootstrap.sh for the install half.

  # DT_NEEDED across all ELF objects in 7.9.1-200326, minus the shared objects
  # the package carries itself. glibc arrives with the nix-ld loader.
  #
  # Not listed, on purpose: OpenSSL 1.0/1.1 and libxml2.so.2. Only
  # libIxpCatalogExp.so and libIxpPatch.so need those, both belong to Patch
  # Management, and this tenant sets that feature to action="0". nixpkgs has
  # no OpenSSL 1.0, refuses to evaluate openssl_1_1, and ships libxml2.so.16
  # rather than .so.2, so enabling Patch Management in policy will break the
  # arrakis service with no clean fix.
  runtimeLibs = with pkgs; [
    stdenv.cc.cc.lib # libstdc++.so.6, libgcc_s.so.1
    zlib # libz.so.1
    libxcrypt-legacy # libcrypt.so.1, needed by lib/libplain.so
    audit # libaudit.so.1, needed by lib/libauparse.so.0
  ];

  # systemd units do not inherit the session nix-ld variables, so every unit
  # sets them itself.
  ldEnv = {
    NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
    NIX_LD_LIBRARY_PATH = lib.makeLibraryPath runtimeLibs;
  };

  # The product shells out to these. A systemd service on NixOS gets a minimal
  # PATH (coreutils, findutils, gnugrep, gnused, systemd) with no tar, so
  # bdsecd logs "sh: line 1: tar: command not found" while unpacking the
  # signature and plugin archives. bin/bdsubmit.sh calls find, tar and xargs.
  # The etc/nad.d network rules call grep, sed and iptables.
  productPath = with pkgs; [
    gnutar
    gzip
    iptables
  ];

  # Shared by the long-running product services, copied from the vendor units.
  common = {
    KillMode = "process";
    Group = "bitdefender";
    UMask = "0077";
    RestartSec = 5;
    Restart = "on-abnormal";
    TimeoutStopSec = 180;
    TimeoutStartSec = 180;
  };
in
{
  options.dotfiles.system.bitdefender = {
    enable = lib.mkEnableOption "Bitdefender GravityZone endpoint agent" // {
      default = false;
    };

    patchManagement = lib.mkEnableOption ''
      the arrakis patch-management service. Leave this off unless nixpkgs
      regains OpenSSL 1.1 and a libxml2.so.2, because the Ixp libraries
      arrakis loads cannot resolve without them
    '';

    edr = lib.mkEnableOption ''
      the osquery daemon. It only does useful work when the GravityZone
      licence covers EDR
    '';
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.nix-ld.enable;
        message = ''
          dotfiles.system.bitdefender needs programs.nix-ld.enable. The agent
          ships foreign FHS binaries and has no ELF interpreter otherwise.
        '';
      }
    ];

    # Makes the same libraries available to an interactive shell, so the bd
    # and bduitool CLIs run without a wrapper.
    programs.nix-ld.libraries = runtimeLibs;

    environment.systemPackages = [
      # dpkg drives the install and every later product upgrade.
      pkgs.dpkg

      # The product lives in /opt and ships a /usr/bin/bd symlink, and neither
      # path is on PATH here, so `sudo bduitool ...` cannot resolve. These thin
      # wrappers put both CLIs where a shell will find them. bduitool runs
      # scans, bd starts and stops the product.
      (pkgs.writeShellScriptBin "bduitool" ''exec ${dir}/bin/bduitool "$@"'')
      (pkgs.writeShellScriptBin "bd" ''exec ${dir}/bin/bd "$@"'')
    ];

    # bootstrap.sh sources this and exports it, so the package maintainer
    # scripts can run the foreign jq and bdconfigure binaries they call.
    environment.etc."bitdefender/ld-env".text = ''
      NIX_LD=${ldEnv.NIX_LD}
      NIX_LD_LIBRARY_PATH=${ldEnv.NIX_LD_LIBRARY_PATH}
    '';

    # The package postinst creates these when they are absent. Declaring them
    # here means the postinst getent checks pass and it skips useradd.
    users = {
      groups.bitdefender = { };
      groups.bduitool = { };
      users.bitdefender = {
        isSystemUser = true;
        group = "bitdefender";
        home = dir;
        createHome = false;
        shell = "${pkgs.shadow}/bin/nologin";
      };
    };

    # NixOS ships only /bin/sh. The product hardcodes three other /bin paths:
    # bdsec.service runs /bin/true, the postinst picks /bin/false as the
    # service account shell, and both the installer feature gate and the
    # hourly bdsubmit script test /bin/systemctl to decide whether systemd is
    # present. Without the systemctl shim the installer silently disables
    # Firewall and NetworkMonitor.
    system.activationScripts.bitdefenderBinShims = ''
      mkdir -p /bin
      ln -sfn ${config.systemd.package}/bin/systemctl /bin/systemctl
      ln -sfn ${pkgs.coreutils}/bin/true /bin/true
      ln -sfn ${pkgs.coreutils}/bin/false /bin/false

      # The package postinst symlinks its hourly redline job into
      # /etc/cron.hourly and aborts when the directory is absent. Nothing on
      # this host runs /etc/cron.hourly, so that symlink stays inert and
      # bdsec-redline.timer does the real work. The directory only has to exist.
      mkdir -p /etc/cron.hourly
    '';

    # Transcribed from /etc/sudoers.d/99-bduitool in the package. NixOS does
    # not read /etc/sudoers.d, so the rule goes into the generated sudoers.
    security.sudo.extraConfig = ''
      Cmnd_Alias BDUITOOL = ${dir}/bin/bduitool get PHASR_detections, \
                            ${dir}/bin/bduitool get PHASR_detections -t *, \
                            ${dir}/bin/bduitool get PHASR_detection *, \
                            ${dir}/bin/bduitool request_access *, \
                            ${dir}/bin/bduitool -h, \
                            ${dir}/bin/bduitool --help, \
                            ${dir}/bin/bduitool ""
      %bduitool ALL=(root) BDUITOOL
    '';

    # Every product service gets the same PATH. Nothing here sets its own, so
    # the merge cannot silently drop one.
    systemd.services = lib.mapAttrs (_: svc: svc // { path = productPath; }) {
      # Umbrella target the other units hang off. The vendor unit runs
      # /bin/true, which does not exist here before the shim above.
      bdsec = {
        description = "Bitdefender Security Tools";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/true";
          RemainAfterExit = true;
        };
      };

      bdsec-daemon = {
        description = "Bitdefender Security Tools Daemon";
        partOf = [ "bdsec.service" ];
        after = [ "bdsec.service" ];
        wantedBy = [ "bdsec.service" ];
        startLimitBurst = 5;
        startLimitIntervalSec = 600;
        environment = ldEnv // {
          BDINSTALLPATH = dir;
          LD_PRELOAD = "${dir}/lib/libmimalloc.so";
        };
        serviceConfig = (removeAttrs common [ "KillMode" ]) // {
          LimitNOFILE = 100000;
          LimitMEMLOCK = "infinity";
          TasksMax = 4096;
          Delegate = true;
          ExecStart = "${dir}/bin/bdsecd -c ${dir}/etc/bdsecd.json";
          ExecStop = "${dir}/bin/bdsecd -c ${dir}/etc/bdsecd.json -k";
        };
      };

      # Talks to the GravityZone console. Without this the endpoint never
      # reports in.
      bdsec-epagng = {
        description = "Bitdefender Security Tools Communication Service";
        partOf = [ "bdsec.service" ];
        after = [ "bdsec.service" ];
        wantedBy = [ "bdsec.service" ];
        startLimitBurst = 5;
        startLimitIntervalSec = 600;
        environment = ldEnv;
        serviceConfig = common // {
          ExecStart = "${dir}/bin/epagngd -c ${dir}/etc/bdsecd.json";
          ExecStop = "${dir}/bin/epagngd -k";
        };
      };

      bdsec-update = {
        description = "Bitdefender Security Tools Update Service";
        partOf = [ "bdsec.service" ];
        after = [
          "bdsec.service"
          "bdsec-daemon.service"
        ];
        wantedBy = [ "bdsec.service" ];
        startLimitBurst = 5;
        startLimitIntervalSec = 600;
        environment = ldEnv;
        serviceConfig =
          (removeAttrs common [
            "TimeoutStopSec"
            "TimeoutStartSec"
          ])
          // {
            ExecStart = "${dir}/bin/updated -c ${dir}/etc/bdsecd.json";
            ExecStop = "${dir}/bin/updated -c ${dir}/etc/bdsecd.json -k";
          };
      };

      bdsec-minidump = {
        description = "Bitdefender Security Tools crash dump submission service";
        environment = ldEnv;
        serviceConfig = {
          Type = "oneshot";
          Group = "bitdefender";
          ExecStart = "${dir}/bin/bdsubmit.sh";
        };
      };

      # The package symlinks redline into /etc/cron.hourly. Nothing on this
      # host runs /etc/cron.hourly, because there is no run-parts chain, so
      # the job becomes a timer instead. The hourly bdsubmit cron job needs no
      # equivalent: it exits early whenever /bin/systemctl exists.
      bdsec-redline = {
        description = "Bitdefender Security Tools redline collector";
        environment = ldEnv;
        serviceConfig = {
          Type = "oneshot";
          Group = "bitdefender";
          ExecStart = "${dir}/bin/redline";
        };
      };

      # Defined even when the feature is off, and only its enablement is gated.
      # The package postinst ends with
      #   ( check relay || check patchmanagementserver ) \
      #     && systemctl enable bdsec-arrakis || systemctl disable bdsec-arrakis
      # and takes the disable branch when neither module is licensed. Disabling
      # a unit systemd has never heard of fails, and postinst runs under set -e,
      # so the unit has to exist for the install to finish. Enabling is safe to
      # leave to the package: NixOS units carry no [Install] section, so
      # systemctl enable reports no installation config and exits 0.
      bdsec-arrakis = {
        description = "Bitdefender Security Tools Patch Management Service";
        partOf = [ "bdsec.service" ];
        after = [
          "bdsec.service"
          "network-online.target"
        ];
        wants = [ "network-online.target" ];
        wantedBy = lib.optionals cfg.patchManagement [ "bdsec.service" ];
        startLimitBurst = 5;
        startLimitIntervalSec = 600;
        environment = ldEnv;
        serviceConfig = common // {
          ExecStart = "${dir}/bin/arrakis -c ${dir}/etc/bdsecd.json";
          ExecStop = "${dir}/bin/arrakis -k";
        };
      };

      # Defined unconditionally for the same reason as bdsec-arrakis, so a
      # maintainer script that disables it cannot abort.
      bdsec-osqueryd = {
        description = "The osquery Daemon";
        after = [
          "network.target"
          "syslog.service"
        ];
        wantedBy = lib.optionals cfg.edr [ "multi-user.target" ];
        environment = ldEnv;
        serviceConfig = {
          TimeoutStartSec = 0;
          EnvironmentFile = "-${dir}/etc/osquery.env";
          ExecStartPre = [
            ''${pkgs.runtimeShell} -c "if [ ! -f $CONFIG_FILE ]; then echo {} > $CONFIG_FILE; fi"''
            ''${pkgs.runtimeShell} -c "if [ ! -f $FLAG_FILE ]; then touch $FLAG_FILE; fi"''
            ''${pkgs.runtimeShell} -c "if [ -f $LOCAL_PIDFILE ]; then mv $LOCAL_PIDFILE $PIDFILE; fi"''
          ];
          ExecStart = "${dir}/bin/osqueryd --flagfile $FLAG_FILE --config_path $CONFIG_FILE";
          Restart = "on-failure";
          KillMode = "control-group";
          KillSignal = "SIGTERM";
        };
      };
    };

    systemd.timers = {
      bdsec-minidump = {
        description = "Bitdefender Security Tools hourly crash dump submission";
        wantedBy = [ "bdsec.service" ];
        timerConfig = {
          OnBootSec = "1h";
          OnUnitActiveSec = "1h";
        };
      };

      bdsec-redline = {
        description = "Bitdefender Security Tools hourly redline collection";
        wantedBy = [ "bdsec.service" ];
        timerConfig = {
          OnBootSec = "1h";
          OnUnitActiveSec = "1h";
        };
      };
    };
  };
}
