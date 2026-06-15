{
  config,
  lib,
  pkgs,
  colors,
  monoFont,
  ...
}:

let
  cfg = config.dotfiles.desktop.eww;
in
{
  options.dotfiles.desktop.eww.enable = lib.mkEnableOption "eww bar + powermenu" // {
    default = true;
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # playerctl feeds the powermenu's now-playing pill (deflisten in
        # eww.yuck); the daemon finds it on PATH via the user profile.
        home.packages = [
          pkgs.eww
          pkgs.playerctl
        ];

        programs.eww.enable = true;

        # home-manager removed programs.eww.configDir (it now offers
        # yuckConfig/scssConfig, which write store copies of eww.yuck/eww.scss
        # and would break hot-reload + the _theme.scss whole-dir symlink).
        # Manage the whole ~/.config/eww directory ourselves as an out-of-store
        # symlink — exactly what the old module did internally
        # (xdg.configFile."eww".source = configDir) — so eww still hot-reloads
        # .yuck/.scss/.nu edits straight from the repo. Version-agnostic: unset
        # configDir is a no-op on the old module too.
        xdg.configFile."eww".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/eww";

        # Palette export for the live-edited stylesheet: eww/eww.scss opens
        # with `@import "theme";`, which resolves to this file. It's written
        # into the repo's eww dir (gitignored) rather than a store-only path
        # so the whole-dir symlink above — and eww's hot reload on it — keeps
        # working. Every `colors` entry becomes an scss `$name: #hex;`, plus
        # `$mono-font` so the stylesheet tracks the theme's font too.
        home.file.".config/nix/eww/_theme.scss".text =
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: value: "\$${name}: #${value};") colors
            ++ [ ''$mono-font: "${monoFont}";'' ]
          )
          + "\n";

        systemd.user.services.eww = {
          Unit = {
            Description = "eww daemon";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "exec";
            ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
            Restart = "always";
            RestartSec = 1;
            # eww.yuck shells out to awk (uptime), `nu ~/.config/eww/media.nu` (media),
            # and playerctl (position/onclick); the powermenu button actions run
            # reboot/poweroff/loginctl (see (pbtn) in eww.yuck). Declare them rather
            # than relying on the inherited user-profile PATH, which is reliable on
            # NixOS but not on Arch.
            Environment = [
              "PATH=${
                lib.makeBinPath [
                  pkgs.eww
                  pkgs.nushell
                  pkgs.playerctl
                  pkgs.gawk
                  pkgs.coreutils
                  pkgs.systemd
                ]
              }"
            ];
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        systemd.user.services.eww-powermenu = {
          Unit = {
            Description = "eww powermenu/bar toggle";
            PartOf = [ "graphical-session.target" ];
            After = [
              "eww.service"
              "graphical-session.target"
            ];
            Wants = [ "eww.service" ];
          };
          Service = {
            Type = "exec";
            ExecStart = "${pkgs.nushell}/bin/nu ${config.home.homeDirectory}/.config/nix/eww/powermenu.nu";
            Restart = "always";
            RestartSec = 1;
            # powermenu.nu only shells out to eww + niri; declare them on PATH
            # rather than relying on the inherited user-profile PATH, which is
            # reliable on NixOS but not on Arch (matches eww.service above).
            Environment = [
              "PATH=${
                lib.makeBinPath [
                  pkgs.eww
                  pkgs.niri
                ]
              }"
            ];
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      }

      (lib.mkIf config.dotfiles.desktop.niri.enable {
        # Escape hatch: a leaked powermenu window is invisible but sits
        # full-screen on the top layer, eating every click. Restarting the
        # daemon drops all its windows, and powermenu.nu closes leftovers on
        # startup, so this recovers even when the daemon itself is wedged.
        programs.niri.settings.binds."Mod+Shift+Q".action.spawn = [
          "systemctl"
          "--user"
          "restart"
          "eww.service"
          "eww-powermenu.service"
        ];
      })
    ]
  );
}
