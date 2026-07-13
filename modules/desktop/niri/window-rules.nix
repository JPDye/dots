{
  colors,
  config,
  lib,
  themeLib,
  shadow-style,
  ...
}:

let
  # Darker than bg1 but still above the bg0 terminal backgrounds the
  # floats sit on — the palette has no step in between, so blend one a
  # quarter of the way up the bg0->bg1 ramp.
  float-shadow = themeLib.mix 0.25 colors.bg0 colors.bg1;
in

{
  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    # These ride the extraConfig escape hatch because niri-flake's settings
    # schema predates them (blur, is-floating matches and per-rule shadows are
    # all niri 26.04+). `blur { off }` is the master switch: niri renders blur
    # as `requested && !blur.off` (background_effect.rs), so this kills the
    # compositor blur for every window and layer regardless of any per-surface
    # request (a bare per-rule `blur false` wouldn't stop client-requested blur).
    dotfiles.desktop.niri.extraConfig = ''
      blur {
          off
      }

      // Floating windows hover over other (often dark) windows, so they get
      // the popup treatment: a hard-edged halo lighter than the tiled bg0
      // shadow (which just masks the gaps and would vanish against dark
      // windows). The border thins to 1px, matching fuzzel's.
      window-rule {
          match is-floating=true
          // Floats open a touch wider than their natural size. This is just a
          // default, so per-app rules still win: blueman's fixed max-width
          // clamps it back to 500, and the dialog list caps at max-width 1000.
          default-column-width {
              fixed 900
          }
          border {
              width 1
          }
          shadow {
              on
              spread 8
              softness 0
              offset x=0 y=0
              color "#${themeLib.alpha shadow-style.opacity float-shadow}"
              // Explicit so unfocused floats don't inherit the layout
              // shadow's bg0 and vanish; focus is already signalled by the
              // border colour.
              inactive-color "#${themeLib.alpha shadow-style.opacity float-shadow}"
          }
      }

      // walker is layer-shell: niri's layer-rule shadow draws around the whole
      // surface (which carries GTK's invisible CSD margin) rather than the
      // visible box, so it never shows. walker's shadow lives in CSS instead
      // (its theme, walker.nix).
    '';

    programs.niri.settings = {
      window-rules = [
        {
          geometry-corner-radius = {
            top-left = 0.0;
            top-right = 0.0;
            bottom-left = 0.0;
            bottom-right = 0.0;
          };

          clip-to-geometry = true;
          draw-border-with-background = false;
          # Opaque baseline. Blur is globally off (extraConfig above), so
          # there's nothing for translucency to reveal; per-app rules can drop
          # this if a window should read see-through.
          opacity = 1.0;
        }
        {
          matches = [ { title = "Firefox"; } ];
          default-column-width = {
            proportion = 1.0;
          };
        }
        {
          matches = [ { app-id = "Spotify"; } ];
          default-column-width = {
            proportion = 1.0;
          };
        }
        {
          matches = [ { app-id = "Slack"; } ];
          default-column-width = {
            proportion = 1.0;
          };
        }
        # Generic sizing classes: any window whose app-id ends in .thin/.wide/
        # .full opens at a preset column width. The work-layout (binds.nix)
        # launches its terminals with `--class=<prefix>.thin` / `.wide`; the
        # dotted suffix is matched here and also satisfies GTK's requirement
        # that app-ids contain a dot.
        {
          matches = [ { app-id = "\\.thin$"; } ];
          default-column-width = {
            proportion = 0.33333;
          };
        }
        {
          matches = [ { app-id = "\\.wide$"; } ];
          default-column-width = {
            proportion = 0.66667;
          };
        }
        {
          matches = [ { app-id = "\\.full$"; } ];
          default-column-width = {
            proportion = 1.0;
          };
        }
        {
          matches = [
            { title = "^(file_progress)$"; }
            { title = "^(confirm)$"; }
            { title = "^(dialog)$"; }
            { title = "^(download)$"; }
            { title = "^(notification )$"; }
            { title = "^(error)$"; }
            { title = "^(splash)$"; }
            { title = "^(nwg-look)$"; }
            { title = "^(confirmreset)$"; }
            { title = "^(Delete profile)$"; }
            { title = "^File Operation Progress$"; }
            { title = "^Confirm to replace files$"; }
            { title = "^KDE Connect URL handler$"; }
            { title = "^(Open File)(.*)$"; }
            { title = "^(Select a File)(.*)$"; }
            { title = "^(Choose wallpaper)(.*)$"; }
            { title = "^(Open Folder)(.*)$"; }
            { title = "^(Save As)(.*)$"; }
            { title = "^(Library)(.*)$"; }
            { title = "^(File Upload)(.*)$"; }
            { title = "^(hyprland-share-picker)$"; }
            { title = "^(.*)-Google$"; }
            { title = "^(.*)System Update$"; }
            { title = "(.*) - Google (.*) - (.*)"; }
            { app-id = "^xdm-app$"; }
            { app-id = "^org.qbittorrent.qBittorrent$"; }
            { app-id = "^org.pulseaudio.pavucontrol$"; }
            { app-id = "^net.davidotek.pupgui2$"; }
          ];
          open-floating = true;
          max-width = 1000;
        }
        {
          # Firefox auth/passkey/security-key dialogs are regular toplevels,
          # not real dialogs, so niri tiles them by default. Float them.
          # Both keys in one match are combined with AND: firefox app-id AND
          # a matching title.
          matches = [
            {
              app-id = "^firefox$";
              title = "(?i)passkey|security key|sign in|authenticat";
            }
          ];
          open-floating = true;
        }
        {
          matches = [ { app-id = ".*blueman.*"; } ];
          open-floating = true;
          min-width = 500;
          max-width = 500;
          min-height = 400;
          max-height = 400;
        }
      ];

      layer-rules = [
        {
          matches = [ { namespace = "^wallpaper$"; } ];
          place-within-backdrop = true;
        }
        {
          matches = [ { namespace = "^eww$"; } ];
          place-within-backdrop = true;
        }
      ];
    };
  };
}
