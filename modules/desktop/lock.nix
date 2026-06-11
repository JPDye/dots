{
  config,
  lib,
  pkgs,
  colors,
  monoFont,
  border-style,
  ...
}:

let
  cfg = config.dotfiles.desktop.lock;
  hyprlock = lib.getExe config.programs.hyprlock.package;
  powerOffMonitors = "${lib.getExe config.programs.niri.package} msg action power-off-monitors";

  # Runs its arguments only while on external power: skips them if any
  # battery reports Discharging. No battery at all counts as powered, so
  # desktop hosts keep the fast timeouts.
  unlessDischarging = pkgs.writeShellScript "unless-discharging" ''
    for supply in /sys/class/power_supply/*/; do
      [ "$(cat "$supply/type" 2>/dev/null)" = Battery ] || continue
      [ "$(cat "$supply/status" 2>/dev/null)" = Discharging ] && exit 0
    done
    exec "$@"
  '';

  # Locks the session, passing extra hyprlock flags through: idle locks add
  # `--grace 5` so a nudge within 5s dismisses them without a password;
  # deliberate locks (keybind, powermenu, suspend) keep the default grace
  # of 0. The pgrep guard turns overlapping fires — both idle tiers,
  # repeated lock events — into no-ops instead of second instances that
  # exit with an error.
  lock = pkgs.writeShellScript "lock" ''
    pgrep -x hyprlock >/dev/null || exec ${hyprlock} "$@"
  '';

  # hyprlock can't fork-once-locked like `swaylock -f`, so to guarantee the
  # session is locked before suspend: spawn it detached, then wait until
  # logind reports the session locked (niri sets LockedHint once the lock
  # surface is up). Gives up after 3s rather than holding the sleep
  # inhibitor if something goes wrong.
  lockBeforeSleep = pkgs.writeShellScript "lock-before-sleep" ''
    if ! pgrep -x hyprlock >/dev/null; then
      ${hyprlock} &
    fi
    for _ in $(seq 30); do
      locked=$(loginctl show-session "''${XDG_SESSION_ID:-self}" --property LockedHint --value 2>/dev/null)
      [ "$locked" = yes ] && exit 0
      sleep 0.1
    done
  '';
in
{
  options.dotfiles.desktop.lock.enable =
    lib.mkEnableOption "screen locking + idle management (hyprlock + swayidle)"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # hyprlock authenticates through PAM: on NixOS that needs
        # security.pam.services.hyprlock (modules/system/desktop.nix); on
        # non-NixOS hosts /etc/pam.d/hyprlock must exist (e.g. install the
        # distro's own hyprlock once) or unlocking will fail.
        #
        # While locked, Ctrl+Alt+F1..F12 still switches to a raw tty — the
        # kernel handles VT switching, so the locker can't (and shouldn't)
        # block it. The graphical session stays locked underneath.
        programs.hyprlock = {
          enable = true;
          package = config.dotfiles.wrapGL pkgs.hyprlock; # GPU-rendered (EGL)

          # Themed from `colors` directly rather than the stylix hyprlock
          # target: that target forces the static wallpaper as the
          # background, and we want the live screenshot. Disabled in
          # modules/theming/stylix.nix.
          settings = {
            general = {
              hide_cursor = true;
              ignore_empty_input = true;
            };

            animations.animation = [
              "fadeIn, 1, 5, linear"
              "fadeOut, 1, 5, linear"
            ];

            background = {
              monitor = "";
              path = "screenshot"; # the live screen, not the wallpaper
              color = "rgb(${colors.bg0})"; # fallback if screencopy fails
              blur_passes = 3;
              blur_size = 7;
              brightness = 0.6;
            };

            input-field = {
              monitor = "";
              size = "280, 48";
              position = "0, -60";
              halign = "center";
              valign = "center";

              outline_thickness = border-style.width;
              rounding = border-style.radius-int;
              fade_on_empty = true;
              placeholder_text = "";

              inner_color = "rgb(${colors.bg0})";
              outer_color = "rgb(${colors.bg3})";
              font_color = "rgb(${colors.fg1})";
              check_color = "rgb(${colors.warning})";
              fail_color = "rgb(${colors.failure})";
            };

            label = [
              # Clock; $TIME is built in and self-updating.
              {
                monitor = "";
                text = "$TIME";
                font_family = monoFont;
                font_size = 72;
                color = "rgb(${colors.fg1})";
                position = "0, 130";
                halign = "center";
                valign = "center";
              }
              # Date below it.
              {
                monitor = "";
                text = ''cmd[update:60000] date +"%A %-d %B"'';
                font_family = monoFont;
                font_size = 16;
                color = "rgb(${colors.fg3})";
                position = "0, 55";
                halign = "center";
                valign = "center";
              }
            ];
          };
        };

        services.swayidle = {
          enable = true;
          timeouts = [
            # On external power: lock after 5 minutes, screens off shortly
            # after; input wakes them.
            {
              timeout = 300;
              command = "${unlessDischarging} ${lock} --grace 5";
            }
            {
              timeout = 330;
              command = "${unlessDischarging} ${powerOffMonitors}";
            }
            # On battery the checks above skip, and this unconditional tier
            # locks later instead. When already locked/off (powered case, or
            # unplugged mid-idle) these are harmless no-ops.
            {
              timeout = 600;
              command = "${lock} --grace 5";
            }
            {
              timeout = 630;
              command = powerOffMonitors;
            }
          ];
          events = {
            # Guarantee the session is locked before suspend/hibernate.
            before-sleep = "${lockBeforeSleep}";
            # `loginctl lock-session` lands here (eww powermenu uses it).
            lock = "${lock}";
          };
        };
      }

      (lib.mkIf config.dotfiles.desktop.niri.enable {
        programs.niri.settings.binds."Mod+Escape".action.spawn = [ "${lock}" ];
      })
    ]
  );
}
