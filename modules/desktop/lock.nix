{
  config,
  lib,
  pkgs,
  colors,
  monoFont,
  serifFont,
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

  # Battery charge + state for the lock screen's status label: a Nerd Font
  # glyph (bolt while charging, fill level otherwise) plus the percentage.
  # Emits nothing on hosts without a battery, so the label is invisible on
  # desktops.
  batteryStatus = pkgs.writeShellScript "battery-status" ''
    for supply in /sys/class/power_supply/*/; do
      [ "$(cat "$supply/type" 2>/dev/null)" = Battery ] || continue
      cap=$(cat "$supply/capacity" 2>/dev/null) || continue
      case "$(cat "$supply/status" 2>/dev/null)" in
        Charging | Full) icon='' ;;
        *)
          if [ "$cap" -ge 90 ]; then icon=''
          elif [ "$cap" -ge 65 ]; then icon=''
          elif [ "$cap" -ge 40 ]; then icon=''
          elif [ "$cap" -ge 15 ]; then icon=''
          else icon=''; fi
          ;;
      esac
      printf "$icon %d%%" "$cap"
      exit 0
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
          # target: we drive the full layout-10 widget arrangement (avatar,
          # name, clock, date, username pill, input) by hand, which the
          # stylix target can't express. That target stays disabled in
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

            # Static wallpaper (the desktop's own), dimmed. hyprlock only
            # applies brightness/contrast/vibrancy inside the blur shader, so
            # a single near-zero blur pass is what lets us dim it — visually
            # still crisp, not the live screenshot.
            background = {
              monitor = "";
              path = "${config.dotfiles.theme.wallpaper}";
              color = "rgb(${colors.bg0})"; # fallback if the image is missing
              blur_passes = 1;
              blur_size = 2;
              brightness = 0.7;
              contrast = 0.9;
              vibrancy = 0.17;
              vibrancy_darkness = 0.0;
              zindex = -3; # below the card's shadow (-2), the card (-1), and every widget (0)
            };

            # Profile photo up top, square-cornered and red-bordered like a
            # niri window. The source is committed at the repo root; keep it
            # git-tracked or the flake build won't see it.
            image = [
              {
                monitor = "";
                path = "${../../avatar.jpg}";
                size = 120;
                rounding = 0;
                border_size = border-style.width;
                border_color = "rgb(${colors.border})";
                position = "0, 190";
                halign = "center";
                valign = "center";
              }
            ];

            # Frosted card behind the whole stack; the avatar straddles its
            # top edge. A translucent panel fakes a pane of smoked glass
            # without real blur (hyprlock can't blur behind a shape). Styled
            # like a niri window: square corners, red border, hard 8px shadow.
            # hyprlock's own shadow_passes always feathers, so the shadow is
            # a solid bg0 shape one layer down, oversized by border + spread
            # on every side (shape borders draw outside `size`). zindex (not
            # file order) enforces cross-widget layering: wallpaper (-3) <
            # shadow (-2) < card (-1) < every label/image/input (0), so the
            # text reads on top. home-manager emits blocks alphabetically, so
            # `shape` would otherwise land last (on top) and hide everything.
            shape = [
              # The hard shadow: card 380x420 + 2 * (2px border + 8px spread).
              {
                monitor = "";
                size = "400, 440";
                color = "rgb(${colors.bg0})"; # same as niri's shadow color
                rounding = 0;
                border_size = 0;
                position = "0, -20";
                halign = "center";
                valign = "center";
                zindex = -2;
              }
              # The glass panel.
              {
                monitor = "";
                size = "380, 420";
                color = "rgba(${colors.bg0}cc)"; # ~80% smoked glass (darker)
                rounding = 0;
                border_size = border-style.width;
                border_color = "rgb(${colors.border})"; # niri's active-border red
                position = "0, -20";
                halign = "center";
                valign = "center";
                zindex = -1;
              }
            ];

            input-field = {
              monitor = "";
              size = "320, 55";
              position = "0, -180";
              halign = "center";
              valign = "center";

              outline_thickness = border-style.width;
              rounding = 0; # square, like the niri windows
              fade_on_empty = false;
              placeholder_text = "<i>Enter password</i>";

              # Password dots: centered, sized/spaced relative to field height.
              dots_size = 0.2;
              dots_spacing = 0.2;
              dots_center = true;

              inner_color = "rgba(${colors.bg0}80)"; # dark glass
              outer_color = "rgb(${colors.border})"; # niri's active-border red until an event recolors it
              font_family = serifFont;
              font_color = "rgb(${colors.fg0})";
              check_color = "rgb(${colors.warning})"; # pulses while PAM checks
              fail_color = "rgb(${colors.failure})"; # wrong password
              capslock_color = "rgb(${colors.yellow})"; # Caps Lock is on
            };

            label = [
              # Username under the avatar.
              {
                monitor = "";
                text = "$USER";
                font_family = serifFont;
                font_size = 22;
                color = "rgb(${colors.fg1})";
                position = "0, 80";
                halign = "center";
                valign = "center";
              }
              # 12-hour clock, center.
              {
                monitor = "";
                text = ''cmd[update:10000] date +"%I:%M"'';
                font_family = serifFont;
                font_size = 60;
                color = "rgb(${colors.fg1})";
                position = "0, -20";
                halign = "center";
                valign = "center";
              }
              # Date under the clock.
              {
                monitor = "";
                text = ''cmd[update:60000] date +"%A, %B %-d"'';
                font_family = serifFont;
                font_size = 18;
                color = "rgb(${colors.fg3})";
                position = "0, -90";
                halign = "center";
                valign = "center";
              }
              # Battery charge + state, top-right; empty on desktops.
              {
                monitor = "";
                text = "cmd[update:30000] ${batteryStatus}";
                font_family = monoFont;
                font_size = 14;
                color = "rgb(${colors.fg3})";
                position = "-24, -24";
                halign = "right";
                valign = "top";
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
