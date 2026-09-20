{
  border-style,
  colors,
  config,
  lib,
  themeLib,
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
    # all niri 26.04+). `blur` is the master switch: niri renders blur as
    # `requested && !blur.off` (background_effect.rs), so `on` only permits
    # blur. Each surface still opts in over ext-background-effect-v1, and the
    # window-rules below do that opting in on the app's behalf. The
    # block takes on/off, passes, noise and saturation and nothing else. It
    # has no radius node. Per-surface control is a separate node, and it is
    # `background-effect { blur ... }` on a window-rule or layer-rule.
    dotfiles.desktop.niri.extraConfig = ''
      blur {
          on
          passes 4
          noise 0.02
          saturation 1.0
      }

      // The master switch only permits blur. A surface still has to ask for
      // it over ext-background-effect-v1, and almost no app asks, so these
      // rules ask on the app's behalf. `background-effect` is absent from
      // niri-flake's typed window-rule schema, so it cannot live in
      // window-rules below. Order also forces it here: niri applies later
      // rules last, extraConfig is appended after the rendered settings, and
      // the firefox opt-out must follow the global opt-in.
      window-rule {
          background-effect {
              blur true
          }
      }
      // `xray` is deliberately unset. niri defaults it to true whenever any
      // background effect is active (background_effect.rs: "since it's
      // cheaper"), and xray samples the wallpaper rather than the windows
      // stacked behind. A blurred wallpaper is the wanted look here, so do
      // not "fix" this by adding `xray false`.

      window-rule {
          match app-id="^firefox$"
          background-effect {
              blur false
          }
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
              color "#${float-shadow}"
              // Explicit so unfocused floats don't inherit the layout
              // shadow's bg0 and vanish; focus is already signalled by the
              // border colour.
              inactive-color "#${float-shadow}"
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
          # Radius from the shared token (modules/theming/palette.nix), so
          # walker's CSS corners and the greeter's cannot drift from these.
          geometry-corner-radius = {
            top-left = border-style.radius-float;
            top-right = border-style.radius-float;
            bottom-left = border-style.radius-float;
            bottom-right = border-style.radius-float;
          };

          clip-to-geometry = true;
          draw-border-with-background = false;
          # Near-opaque baseline. niri fades the whole surface, text
          # included, so this stays close to 1.0. It is also the aperture for
          # the blur: the effect draws behind the window, so only 1 - opacity
          # of it shows. A per-app rule can set 1.0 back.
          opacity = 0.92;
        }
        {
          matches = [ { title = "Firefox"; } ];
          default-column-width = {
            proportion = 1.0;
          };
        }
        {
          # Firefox opts out of the translucent baseline. An opaque window
          # shows nothing behind it, so this also hides any blur under it.
          # niri 26.04 has no per-window blur node, so opacity is the only
          # per-app control available.
          matches = [ { app-id = "^firefox$"; } ];
          opacity = 1.0;
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
